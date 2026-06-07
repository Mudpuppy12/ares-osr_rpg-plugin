module AresMUSH
  module OsrRpg
    describe 'Equipment and commerce' do
      before do
        allow(Global).to receive(:read_config).and_call_original
        allow(Global).to receive(:read_config).with('osr_rpg', 'default_ac').and_return(0)
        allow(Global).to receive(:read_config).with('osr_rpg', 'ac_baseline').and_return(9)
        allow(Global).to receive(:read_config).with('osr', 'equipment').and_return({
          'armor' => {
            'leather' => { 'name' => 'Leather', 'ac' => 2, 'cost' => 20 },
            'plate' => { 'name' => 'Plate Mail', 'ac' => 6, 'cost' => 60 },
            'shield' => { 'name' => 'Shield', 'ac_bonus' => 1, 'cost' => 10 }
          },
          'weapons' => {
            'sword' => { 'name' => 'Sword', 'damage' => '1d8', 'cost' => 10 }
          },
          'adventuring_gear' => {
            'torch' => { 'name' => 'Torch', 'cost' => 1 }
          }
        })
        @char = double('char',
                       osr_gold: 100,
                       osr_starting_gold: 100,
                       osr_inventory: {},
                       osr_equipment: [],
                       osr_ac: 0)
        allow(@char).to receive(:update) { |attrs| attrs.each { |k, v| allow(@char).to receive(k).and_return(v) } }
      end

      describe 'ascending AC' do
        it 'stacks plate and shield to AC 7' do
          ac = EquipmentHelper.suggest_ac_for_list(%w[plate shield])
          expect(ac).to eq 7
        end

        it 'converts attack target using ascending AC' do
          expect(CommandHelpers.attack_needed_roll(19, 0)).to eq 10
          expect(CommandHelpers.attack_needed_roll(19, 7)).to eq 17
        end
      end

      describe 'cart_total' do
        it 'sums item costs by quantity' do
          total = EquipmentHelper.cart_total({ 'leather' => 1, 'torch' => 3 })
          expect(total).to eq 23
        end
      end

      describe 'buy_item' do
        it 'deducts gold and adds inventory' do
          result = EquipmentHelper.buy_item(@char, 'torch', 2)
          expect(result[:cost]).to eq 2
          expect(result[:gold]).to eq 98
        end

        it 'rejects insufficient gold' do
          allow(@char).to receive(:osr_gold).and_return(1)
          result = EquipmentHelper.buy_item(@char, 'plate', 1)
          expect(result[:error]).to eq t('osr_rpg.insufficient_gold', cost: 60, gold: 1)
        end
      end

      describe 'sell_item' do
        it 'credits half price and removes inventory' do
          allow(@char).to receive(:osr_inventory).and_return({ 'torch' => 2 })
          result = EquipmentHelper.sell_item(@char, 'torch', 1)
          expect(result[:credit]).to eq 0
          expect(result[:gold]).to eq 100
        end
      end

      describe 'equip_item' do
        it 'requires inventory ownership' do
          result = EquipmentHelper.equip_item(@char, 'sword')
          expect(result[:error]).to eq t('osr_rpg.inventory_not_owned', item: 'sword')
        end

        it 'moves owned item to equipped and updates AC' do
          allow(@char).to receive(:osr_inventory).and_return({ 'leather' => 1, 'shield' => 1 })
          result = EquipmentHelper.equip_item(@char, 'leather')
          expect(result[:ac]).to eq 2
        end
      end

      describe 'validate_inventory' do
        it 'rejects cart over budget' do
          allow(@char).to receive(:osr_starting_gold).and_return(50)
          alerts = Chargen.validate_inventory('fighter', { 'plate' => 1 }, 50)
          expect(alerts).to include(t('osr_rpg.cart_over_budget', total: 60, budget: 50))
        end
      end

      describe 'migrate_character!' do
        it 'does not copy equipped items into empty inventory' do
          updates = {}
          allow(@char).to receive(:osr_inventory).and_return({})
          allow(@char).to receive(:osr_equipment).and_return(%w[leather shield])
          allow(@char).to receive(:update) { |attrs| updates.merge!(attrs) }

          EquipmentHelper.migrate_character!(@char)

          expect(updates).not_to have_key(:osr_inventory)
        end

        it 'removes equipped items duplicated in carried inventory' do
          updates = {}
          allow(@char).to receive(:osr_inventory).and_return({ 'leather' => 1, 'torch' => 2 })
          allow(@char).to receive(:osr_equipment).and_return(['leather'])
          allow(@char).to receive(:update) { |attrs| updates.merge!(attrs) }

          EquipmentHelper.migrate_character!(@char)

          expect(updates[:osr_inventory]).to eq({ 'torch' => 2 })
        end

        it 'dedupes duplicate equipped entries' do
          updates = {}
          allow(@char).to receive(:osr_inventory).and_return({})
          allow(@char).to receive(:osr_equipment).and_return(%w[sword sword])
          allow(@char).to receive(:update) { |attrs| updates.merge!(attrs) }

          EquipmentHelper.migrate_character!(@char)

          expect(updates[:osr_equipment]).to eq(['sword'])
        end
      end

      describe 'merge_equipped_into_inventory' do
        it 'adds equipped items missing from the submitted cart' do
          allow(@char).to receive(:osr_equipment).and_return(['leather', 'shield'])
          merged = EquipmentHelper.merge_equipped_into_inventory(@char, { 'torch' => 2 })
          expect(merged).to eq({ 'torch' => 2, 'leather' => 1, 'shield' => 1 })
        end

        it 'does not duplicate items already in the cart' do
          allow(@char).to receive(:osr_equipment).and_return(['leather'])
          merged = EquipmentHelper.merge_equipped_into_inventory(@char, { 'leather' => 1, 'torch' => 1 })
          expect(merged).to eq({ 'leather' => 1, 'torch' => 1 })
        end
      end

      describe 'inventory_display' do
        it 'marks armor and weapons as equippable' do
          allow(@char).to receive(:osr_inventory).and_return({ 'leather' => 1, 'torch' => 2 })
          rows = EquipmentHelper.inventory_display(@char)
          leather = rows.find { |r| r[:key] == 'leather' }
          torch = rows.find { |r| r[:key] == 'torch' }
          expect(leather[:equippable]).to be true
          expect(torch[:equippable]).to be false
        end
      end

      describe 'EquipRequestHandler' do
        let(:enactor) { @char }

        before do
          allow(Website).to receive(:check_login).and_return(nil)
          allow(Leveling).to receive(:sheet_ready?).and_return(true)
          allow(Chargen).to receive(:build_sheet_display).and_return({ inventory: [], equipment: [] })
        end

        it 'equips an owned item' do
          allow(@char).to receive(:osr_inventory).and_return({ 'leather' => 1 })
          allow(EquipmentHelper).to receive(:equip_item).and_return({ ac: 2, equipment: ['leather'] })
          request = double('request', enactor: enactor, args: { 'action' => 'equip', 'item' => 'leather' })
          result = EquipRequestHandler.new.handle(request)
          expect(result[:ac]).to eq 2
          expect(result[:sheet]).not_to be_nil
        end

        it 'rejects when sheet is not ready' do
          allow(Leveling).to receive(:sheet_ready?).and_return(false)
          request = double('request', enactor: enactor, args: { 'action' => 'equip', 'item' => 'leather' })
          result = EquipRequestHandler.new.handle(request)
          expect(result[:error]).to eq t('osr_rpg.no_sheet_for_levelup')
        end

        it 'returns equip helper errors' do
          allow(EquipmentHelper).to receive(:equip_item).and_return({ error: t('osr_rpg.inventory_not_owned', item: 'sword') })
          request = double('request', enactor: enactor, args: { 'action' => 'equip', 'item' => 'sword' })
          result = EquipRequestHandler.new.handle(request)
          expect(result[:error]).to eq t('osr_rpg.inventory_not_owned', item: 'sword')
        end
      end
    end
  end
end
