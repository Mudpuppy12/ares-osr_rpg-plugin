module AresMUSH
  module OsrRpg
    describe 'Chargen' do
      before do
        @char = double('char')
        allow(@char).to receive(:update)
        allow(@char).to receive(:osr_starting_gold).and_return(nil)
        allow(@char).to receive(:osr_class).and_return(nil)
        allow(@char).to receive(:osr_alignment).and_return(nil)
        allow(@char).to receive(:osr_ability_scores).and_return({})
        allow(@char).to receive(:osr_thief_skills).and_return({})
        allow(@char).to receive(:osr_thac0).and_return(nil)
        allow(@char).to receive(:osr_ability_roll_count).and_return(0)
        allow(@char).to receive(:osr_spell_book).and_return({})
        allow(@char).to receive(:osr_inventory).and_return({})
        allow(@char).to receive(:osr_gold).and_return(nil)
      end

      describe 'ensure_starting_gold!' do
        it 'rolls when starting gold is unset' do
          updates = {}
          allow(@char).to receive(:update) { |attrs| updates.merge!(attrs) }
          gold = Chargen.ensure_starting_gold!(@char)
          expect(gold).to be >= 30
          expect(updates[:osr_starting_gold]).to eq(gold)
        end

        it 'rolls when starting gold is zero' do
          updates = {}
          allow(@char).to receive(:osr_starting_gold).and_return(0)
          allow(@char).to receive(:update) { |attrs| updates.merge!(attrs) }
          gold = Chargen.ensure_starting_gold!(@char)
          expect(gold).to be >= 30
          expect(updates[:osr_starting_gold]).to eq(gold)
        end

        it 'keeps an existing rolled budget' do
          allow(@char).to receive(:osr_starting_gold).and_return(120)
          expect(@char).not_to receive(:update)
          expect(Chargen.ensure_starting_gold!(@char)).to eq(120)
        end
      end

      describe 'validate' do
        it 'requires class' do
          alerts = Chargen.validate(@char, nil, 'Law', { 'str' => 10 }, {})
          expect(alerts).to include(t('osr_rpg.class_not_set'))
        end

        it 'rejects assassin with Lawful alignment' do
          scores = { 'str' => 10, 'dex' => 13, 'con' => 10, 'int' => 10, 'wis' => 10, 'cha' => 10 }
          alerts = Chargen.validate(@char, 'assassin', 'Law', scores, {})
          expect(alerts).to include(t('osr_rpg.invalid_alignment', alignment: 'Law'))
        end

        it 'accepts paladin with Lawful alignment' do
          scores = { 'str' => 13, 'dex' => 10, 'con' => 10, 'int' => 10, 'wis' => 13, 'cha' => 10 }
          alerts = Chargen.validate(@char, 'paladin', 'Law', scores, {})
          expect(alerts).not_to include(t('osr_rpg.invalid_alignment', alignment: 'Law'))
        end

        it 'validates thief expertise points' do
          scores = { 'str' => 10, 'dex' => 13, 'con' => 10, 'int' => 10, 'wis' => 10, 'cha' => 10 }
          skills = { 'hide_in_shadows' => 2, 'move_silently' => 1 }
          alerts = Chargen.validate(@char, 'thief', 'Neutrality', scores, skills)
          expect(alerts).to include(t('osr_rpg.thief_points_wrong', points: 4, spent: 3))
        end

        it 'rejects disallowed class for new chargen' do
          allow(Global).to receive(:read_config).and_wrap_original do |method, *args|
            args == ['osr_rpg', 'allowed_classes'] ? ['fighter'] : method.call(*args)
          end
          scores = { 'str' => 13, 'dex' => 10, 'con' => 12, 'int' => 10, 'wis' => 10, 'cha' => 10 }
          allow(@char).to receive(:osr_class).and_return(nil)
          alerts = Chargen.validate(@char, 'thief', 'Neutrality', scores, {})
          expect(alerts).to include(t('osr_rpg.class_not_allowed', class: 'thief'))
        end

        it 'grandfathers existing character on disallowed class' do
          allow(Global).to receive(:read_config).and_wrap_original do |method, *args|
            args == ['osr_rpg', 'allowed_classes'] ? ['fighter'] : method.call(*args)
          end
          scores = { 'str' => 10, 'dex' => 13, 'con' => 10, 'int' => 10, 'wis' => 10, 'cha' => 10 }
          skills = { 'hide_in_shadows' => 2, 'move_silently' => 1, 'climb_walls' => 1, 'find_traps' => 0 }
          allow(@char).to receive(:osr_class).and_return('thief')
          alerts = Chargen.validate(@char, 'thief', 'Neutrality', scores, skills)
          expect(alerts).not_to include(t('osr_rpg.class_not_allowed', class: 'thief'))
        end

        it 'requires arcane caster to pick L1 spells' do
          scores = { 'str' => 10, 'dex' => 10, 'con' => 10, 'int' => 13, 'wis' => 10, 'cha' => 10 }
          alerts = Chargen.validate(@char, 'magic_user', 'Neutrality', scores, {}, {})
          expect(alerts).to include(t('osr_rpg.spell_picks_wrong', required: 1, picked: 0))
        end

        it 'warns when cart is not saved due to other validation failures' do
          allow(Global).to receive(:read_config).and_call_original
          allow(Global).to receive(:read_config).with('osr', 'equipment').and_return({
            'adventuring_gear' => { 'torch' => { 'name' => 'Torch', 'cost' => 1 } }
          })
          allow(@char).to receive(:osr_starting_gold).and_return(100)
          scores = { 'str' => 13, 'dex' => 10, 'con' => 12 }
          alerts = Chargen.validate(@char, 'fighter', 'Law', scores, {}, {}, { 'torch' => 1 })
          expect(alerts).to include(t('osr_rpg.ability_not_set', ability: 'INT'))
          expect(alerts).to include(t('osr_rpg.cart_not_saved'))
        end
      end

      describe 'set_spell_book' do
        it 'sets arcane L1 spell' do
          allow(@char).to receive(:osr_class).and_return('magic_user')
          allow(@char).to receive(:update)
          result = Chargen.set_spell_book(@char, ['Magic Missile'])
          expect(result).to eq true
          expect(@char).to have_received(:update).with(hash_including(osr_spell_book: { '1' => ['Magic Missile'] }))
        end

        it 'rejects invalid spell count' do
          allow(@char).to receive(:osr_class).and_return('magic_user')
          result = Chargen.set_spell_book(@char, [])
          expect(result).to include(t('osr_rpg.spell_picks_wrong', required: 1, picked: 0))
        end
      end

      describe 'Tables.class_allowed?' do
        it 'allows all when allowlist empty' do
          allow(Global).to receive(:read_config).and_wrap_original do |method, *args|
            args == ['osr_rpg', 'allowed_classes'] ? [] : method.call(*args)
          end
          expect(Tables.class_allowed?('drow')).to be true
        end

        it 'filters to allowlist when set' do
          allow(Global).to receive(:read_config).and_wrap_original do |method, *args|
            args == ['osr_rpg', 'allowed_classes'] ? ['fighter', 'cleric'] : method.call(*args)
          end
          expect(Tables.class_allowed?('fighter')).to be true
          expect(Tables.class_allowed?('drow')).to be false
        end
      end

      describe 'Tables.roll_3d6' do
        it 'returns a value between 3 and 18' do
          20.times do
            roll = Tables.roll_3d6
            expect(roll).to be_between(3, 18)
          end
        end
      end

      describe 'Tables.parse_key_value_pairs' do
        it 'parses slash-separated pairs' do
          pairs = Tables.parse_key_value_pairs('str=14/dex=12')
          expect(pairs).to eq({ 'str' => '14', 'dex' => '12' })
        end
      end

      describe 'increment_ability_roll_count' do
        it 'increments and returns the new total' do
          allow(@char).to receive(:osr_ability_roll_count).and_return(2)
          allow(@char).to receive(:update) do |attrs|
            @roll_count = attrs[:osr_ability_roll_count]
          end

          count = Chargen.increment_ability_roll_count(@char)
          expect(count).to eq(3)
          expect(@roll_count).to eq(3)
        end
      end

      describe 'roll_abilities' do
        it 'merges rolled scores into character' do
          allow(@char).to receive(:osr_ability_scores).and_return({ 'str' => 10 })
          allow(@char).to receive(:update) do |attrs|
            @stored_scores = attrs[:osr_ability_scores] if attrs[:osr_ability_scores]
            @roll_count = attrs[:osr_ability_roll_count] if attrs.key?(:osr_ability_roll_count)
          end

          rolled = Chargen.roll_abilities(@char, ['dex'])
          expect(rolled['dex']).to be_between(3, 18)
          expect(@stored_scores['str']).to eq(10)
          expect(@stored_scores['dex']).to eq(rolled['dex'])
          expect(@roll_count).to eq(1)
        end

        it 'increments roll count once per command' do
          updates = []
          allow(@char).to receive(:osr_ability_scores).and_return({})
          allow(@char).to receive(:update) { |attrs| updates << attrs }

          Chargen.roll_abilities(@char, Tables.abilities)
          roll_count_updates = updates.select { |attrs| attrs.key?(:osr_ability_roll_count) }
          expect(roll_count_updates.length).to eq(1)
          expect(roll_count_updates.first[:osr_ability_roll_count]).to eq(1)
        end
      end

      describe 'reset_char' do
        it 'clears OSR fields' do
          updates = nil
          allow(@char).to receive(:update) { |attrs| updates = attrs }
          Chargen.reset_char(@char)
          expect(updates[:osr_class]).to be_nil
          expect(updates[:osr_ability_scores]).to eq({})
          expect(updates[:osr_thief_skills]).to eq({})
          expect(updates[:osr_hp]).to be_nil
          expect(updates[:osr_ability_roll_count]).to eq(0)
        end
      end

      describe 'build_exploration_display' do
        before do
          allow(CommandHelpers).to receive(:sheet_applied?).and_return(true)
        end

        it 'uses racial special ability bonus for listen at door' do
          abilities = ['Listen at doors 2-in-6']
          display = Chargen.build_exploration_display(@char, abilities)
          listen = display.find { |sk| sk[:key] == 'listen_at_door' }
          expect(listen[:chance]).to eq('2-in-6')
        end

        it 'uses thief hear_noise skill when higher than base' do
          allow(@char).to receive(:osr_thief_skills).and_return({ 'hear_noise' => 3 })
          display = Chargen.build_exploration_display(@char, [])
          listen = display.find { |sk| sk[:key] == 'listen_at_door' }
          expect(listen[:chance]).to eq('3-in-6')
        end

        it 'uses the best bonus from thief skill and special abilities' do
          allow(@char).to receive(:osr_thief_skills).and_return({ 'find_remove_traps' => 2 })
          abilities = ['Detect room traps 3-in-6']
          display = Chargen.build_exploration_display(@char, abilities)
          traps = display.find { |sk| sk[:key] == 'find_room_trap' }
          expect(traps[:chance]).to eq('3-in-6')
        end

        it 'excludes exploration thief skills from class skill display' do
          allow(@char).to receive(:osr_thief_skills).and_return({
            'hear_noise' => 2,
            'hide_in_shadows' => 1
          })
          display = Chargen.build_thief_display(@char)
          keys = display.map { |sk| sk[:key] }
          expect(keys).not_to include('hear_noise')
          expect(keys).to include('hide_in_shadows')
        end
      end

      describe 'reset_shop!' do
        it 'clears inventory, equipment, and gold budget' do
          updates = {}
          allow(@char).to receive(:update) { |attrs| updates.merge!(attrs) }
          Chargen.reset_shop!(@char)
          expect(updates[:osr_inventory]).to eq({})
          expect(updates[:osr_equipment]).to eq([])
          expect(updates[:osr_starting_gold]).to be_nil
          expect(updates[:osr_gold]).to be_nil
        end
      end

      describe 'save_char' do
        before do
          allow(Global).to receive(:read_config).and_call_original
          allow(Global).to receive(:read_config).with('osr_rpg', 'default_ac').and_return(0)
          allow(Global).to receive(:read_config).with('osr', 'equipment').and_return({
            'armor' => {
              'leather' => { 'name' => 'Leather', 'ac' => 2, 'cost' => 20 },
              'shield' => { 'name' => 'Shield', 'ac_bonus' => 1, 'cost' => 10 }
            },
            'weapons' => {
              'sword' => { 'name' => 'Sword', 'damage' => '1d8', 'cost' => 10 }
            },
            'adventuring_gear' => {
              'torch' => { 'name' => 'Torch', 'cost' => 1 }
            }
          })
        end

        it 'commits cart to inventory and gold on a valid full sheet save' do
          scores = {
            'str' => 13, 'dex' => 10, 'con' => 12,
            'int' => 10, 'wis' => 10, 'cha' => 10
          }
          inventory = { 'leather' => 1, 'torch' => 2 }
          updates = {}
          allow(@char).to receive(:osr_starting_gold).and_return(100)
          allow(@char).to receive(:osr_class).and_return(nil)
          allow(@char).to receive(:osr_equipment).and_return([])
          allow(@char).to receive(:update) do |attrs|
            updates.merge!(attrs)
            attrs.each { |k, v| allow(@char).to receive(k).and_return(v) }
          end

          alerts = Chargen.save_char(@char, {
            'class' => 'fighter',
            'alignment' => 'Law',
            'ability_scores' => scores,
            'thief_skills' => {},
            'spell_book' => {},
            'inventory' => inventory
          })

          expect(alerts).to be_empty
          expect(updates[:osr_gold]).to eq(78)
          expect(updates[:osr_inventory]).to eq({ 'torch' => 2 })
          expect(updates[:osr_equipment]).to include('leather')
          expect(updates[:osr_ac]).to eq(2)
        end

        it 'resets shop when class changes before applying a new sheet' do
          scores = {
            'str' => 13, 'dex' => 10, 'con' => 12,
            'int' => 10, 'wis' => 10, 'cha' => 10
          }
          updates = {}
          allow(@char).to receive(:osr_class).and_return('fighter')
          allow(@char).to receive(:osr_starting_gold).and_return(100)
          allow(@char).to receive(:osr_inventory).and_return({ 'torch' => 3 })
          allow(@char).to receive(:osr_equipment).and_return(['leather'])
          allow(@char).to receive(:update) do |attrs|
            updates.merge!(attrs)
            attrs.each { |k, v| allow(@char).to receive(k).and_return(v) }
          end

          Chargen.save_char(@char, {
            'class' => 'thief',
            'alignment' => 'Neutrality',
            'ability_scores' => scores,
            'thief_skills' => { 'hide_in_shadows' => 2, 'move_silently' => 1, 'climb_walls' => 1 },
            'spell_book' => {},
            'inventory' => { 'torch' => 1 }
          })

          expect(updates[:osr_inventory]).to eq({ 'torch' => 1 })
          expect(updates[:osr_starting_gold]).to be >= 30
        end

        it 'does not commit inventory when validation fails' do
          updates = {}
          allow(@char).to receive(:osr_starting_gold).and_return(100)
          allow(@char).to receive(:update) { |attrs| updates.merge!(attrs) }

          alerts = Chargen.save_char(@char, {
            'class' => 'fighter',
            'alignment' => 'Law',
            'ability_scores' => { 'str' => 13 },
            'inventory' => { 'torch' => 1 }
          })

          expect(alerts).not_to be_empty
          expect(updates).not_to have_key(:osr_inventory)
        end
      end

      describe 'finish_char' do
        it 'returns alerts when sheet is incomplete' do
          allow(@char).to receive(:osr_class).and_return(nil)
          alerts = Chargen.finish_char(@char)
          expect(alerts).to include(t('osr_rpg.class_not_set'))
        end

        it 'applies sheet when valid' do
          scores = { 'str' => 13, 'dex' => 10, 'con' => 12, 'int' => 10, 'wis' => 10, 'cha' => 10 }
          allow(@char).to receive(:osr_class).and_return('fighter')
          allow(@char).to receive(:osr_alignment).and_return('Law')
          allow(@char).to receive(:osr_ability_scores).and_return(scores)
          allow(@char).to receive(:osr_starting_gold).and_return(100)
          updates = {}
          allow(@char).to receive(:update) { |attrs| updates.merge!(attrs) }

          alerts = Chargen.finish_char(@char)
          expect(alerts).to be_empty
          expect(updates[:osr_hp]).to be >= 1
          expect(updates[:osr_thac0]).not_to be_nil
          expect(updates[:osr_starting_gold]).to be >= 30
          expect(updates[:osr_gold]).to be >= 0
        end
      end
    end
  end
end
