module AresMUSH
  module OsrRpg
    describe 'Rolls' do
      before do
        @char = double('char',
                       name: 'Tester',
                       osr_class: 'fighter',
                       osr_level: 1,
                       osr_thac0: 19,
                       osr_saving_throws: { 'death' => 12, 'wands' => 13 },
                       osr_thief_skills: { 'hide_in_shadows' => 3 },
                       osr_ability_scores: { 'str' => 14 })
        allow(Leveling).to receive(:sheet_ready?).with(@char).and_return(true)
        allow(@char).to receive(:fullname).and_return('Test Fighter')
        allow(Chargen).to receive(:build_sheet_display).with(@char).and_return(
          class_name: 'Fighter',
          class_key: 'fighter',
          level: 1,
          hp: 8,
          hp_max: 8,
          ac: 5,
          thac0: 19,
          saves: { death: 12 },
          thief_skills: [],
          abilities: [{ key: 'str', name: 'STR', score: 14, modifier: 1 }],
          equipment: [{ name: 'Sword', key: 'sword' }],
          inventory: [],
          can_level_up: false,
          xp: 0,
          xp_to_next_level: 2000,
          expertise_unspent: 0
        )
        allow(Website).to receive(:icon_for_char).with(@char).and_return('icon/test.png')
        allow(CommandHelpers).to receive(:sheet_applied?).with(@char).and_return(true)
      end

      describe 'scene_sheet' do
        it 'returns full sheet display with portrait metadata when ready' do
          sheet = Rolls.scene_sheet(@char)
          expect(sheet[:class_name]).to eq 'Fighter'
          expect(sheet[:thac0]).to eq 19
          expect(sheet[:abilities].length).to eq 1
          expect(sheet[:char_name]).to eq 'Tester'
          expect(sheet[:name]).to eq 'Test Fighter'
          expect(sheet[:icon]).to eq 'icon/test.png'
        end

        it 'returns nil when sheet not ready' do
          allow(Leveling).to receive(:sheet_ready?).with(@char).and_return(false)
          expect(Rolls.scene_sheet(@char)).to be_nil
        end
      end

      describe 'roll_attack' do
        it 'returns d20 roll and message' do
          allow(Rolls).to receive(:rand).and_return(15) if Rolls.respond_to?(:rand)
          result = Rolls.roll_attack(@char)
          expect(result[:roll]).to be_between(1, 20)
          expect(result[:message]).to include('Tester')
          expect(result[:message]).to include('19')
        end
      end

      describe 'roll_save' do
        it 'rejects invalid category' do
          result = Rolls.roll_save(@char, 'invalid')
          expect(result[:error]).to eq t('osr_rpg.invalid_save_category', category: 'invalid')
        end

        it 'rolls against save target' do
          result = Rolls.roll_save(@char, 'death')
          expect(result[:roll]).to be_between(1, 20)
          expect(result[:target]).to eq 12
        end
      end

      describe 'roll_thief_skill' do
        it 'rejects unknown skill' do
          result = Rolls.roll_thief_skill(@char, 'invalid_skill')
          expect(result[:error]).to eq t('osr_rpg.invalid_thief_skill', skill: 'invalid_skill')
        end

        it 'rolls d6 for known skill' do
          result = Rolls.roll_thief_skill(@char, 'hide_in_shadows')
          expect(result[:roll]).to be_between(1, 6)
          expect(result[:chance]).to eq 3
        end
      end

      describe 'roll_ability_check' do
        it 'rejects invalid ability' do
          result = Rolls.roll_ability_check(@char, 'foo')
          expect(result[:error]).to eq t('osr_rpg.invalid_ability', ability: 'foo')
        end

        it 'includes modifier in result' do
          result = Rolls.roll_ability_check(@char, 'str')
          expect(result[:modifier]).to eq 1
          expect(result[:total]).to eq result[:roll] + 1
        end
      end

      describe 'roll_generic' do
        it 'rolls a single dice expression with total' do
          allow(Rolls).to receive(:random_die).with(6).and_return(3, 5)
          result = Rolls.roll_generic('Tester', '2d6')
          expect(result[:message]).to include('Tester rolls 2d6: 3, 5.')
          expect(result[:message]).to include('Total: 8.')
        end

        it 'rolls compound dice expressions with combined total' do
          allow(Rolls).to receive(:random_die).with(6).and_return(3, 5)
          allow(Rolls).to receive(:random_die).with(20).and_return(14)
          result = Rolls.roll_generic('Tester', '2d6+1d20')
          expect(result[:message]).to include('Tester rolls 2d6: 3, 5.')
          expect(result[:message]).to include('Tester rolls 1d20: 14.')
          expect(result[:message]).to include('Total: 22.')
        end

        it 'rejects invalid dice strings' do
          expect(Rolls.roll_generic('Tester', '')).to have_key(:error)
          expect(Rolls.roll_generic('Tester', 'bad')).to have_key(:error)
        end
      end
    end
  end
end
