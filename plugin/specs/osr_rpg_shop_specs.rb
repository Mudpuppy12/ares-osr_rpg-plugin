module AresMUSH
  module OsrRpg
    describe 'Post-chargen shop' do
      before do
        allow(Global).to receive(:read_config).and_call_original
        allow(Global).to receive(:read_config).with('osr_rpg', 'default_ac').and_return(0)
        allow(Global).to receive(:read_config).with('osr_rpg', 'ac_baseline').and_return(9)
        allow(Global).to receive(:read_config).with('osr', 'equipment').and_return({
          'weapons' => {
            'torch' => { 'name' => 'Torch', 'cost' => 1 }
          },
          'adventuring_gear' => {}
        })
        allow(Global).to receive(:read_config).with('osr_rpg', 'magic_consumables').and_return({
          'potion_healing' => { 'name' => 'Potion of Healing', 'cost' => 500 }
        })
        allow(Global).to receive(:read_config).with('osr_rpg', 'magic_scrolls').and_return({
          'scroll_l1_magic_missile' => {
            'name' => 'Scroll of Magic Missile',
            'cost' => 500,
            'spell' => 'Magic Missile',
            'level' => 1,
            'arcane_only' => true
          }
        })
        allow(Global).to receive(:read_config).with('osr_rpg', 'shop_blurb').and_return('Shop blurb')

        @char = double('char',
                       osr_gold: 1000,
                       osr_starting_gold: 1000,
                       osr_inventory: {},
                       osr_equipment: [],
                       osr_ac: 0,
                       osr_class: 'cleric')
        allow(@char).to receive(:is_approved?).and_return(true)
        allow(@char).to receive(:update) { |attrs| attrs.each { |k, v| allow(@char).to receive(k).and_return(v) } }
        allow(Leveling).to receive(:sheet_ready?).with(@char).and_return(true)
      end

      describe 'eligible?' do
        it 'requires approval and a finalized sheet' do
          expect(ShopHelper.eligible?(@char)).to eq true

          allow(@char).to receive(:is_approved?).and_return(false)
          expect(ShopHelper.eligible?(@char)).to eq false

          allow(@char).to receive(:is_approved?).and_return(true)
          allow(Leveling).to receive(:sheet_ready?).with(@char).and_return(false)
          expect(ShopHelper.eligible?(@char)).to eq false
        end
      end

      describe 'buy_item' do
        it 'rejects unapproved characters' do
          allow(@char).to receive(:is_approved?).and_return(false)
          result = ShopHelper.buy_item(@char, 'torch', 1)
          expect(result[:error]).to eq t('osr_rpg.shop_not_eligible')
        end

        it 'buys mundane gear and potions' do
          result = ShopHelper.buy_item(@char, 'torch', 2)
          expect(result[:cost]).to eq 2
          expect(result[:gold]).to eq 998

          result = ShopHelper.buy_item(@char, 'potion_healing', 1)
          expect(result[:cost]).to eq 500
          expect(result[:gold]).to eq 498
        end

        it 'rejects scroll purchase for divine casters' do
          result = ShopHelper.buy_item(@char, 'scroll_l1_magic_missile', 1)
          expect(result[:error]).to eq t('osr_rpg.shop_scroll_arcane_only')
        end

        it 'allows scroll purchase for arcane casters' do
          allow(@char).to receive(:osr_class).and_return('magic_user')
          allow(Tables).to receive(:casting_type).with('magic_user').and_return('arcane')

          result = ShopHelper.buy_item(@char, 'scroll_l1_magic_missile', 1)
          expect(result[:cost]).to eq 500
          expect(result[:item]).to eq 'Scroll of Magic Missile'
        end
      end

      describe 'sell_item' do
        it 'credits half price' do
          allow(@char).to receive(:osr_inventory).and_return({ 'torch' => 2 })
          result = ShopHelper.sell_item(@char, 'torch', 1)
          expect(result[:credit]).to eq 0
          expect(result[:gold]).to eq 1000
        end

        it 'blocks selling equipped items' do
          allow(@char).to receive(:osr_inventory).and_return({ 'torch' => 1 })
          allow(@char).to receive(:osr_equipment).and_return(['torch'])
          result = ShopHelper.sell_item(@char, 'torch', 1)
          expect(result[:error]).to eq t('osr_rpg.cannot_sell_equipped', item: 'Torch')
        end
      end

      describe 'inventory_display' do
        it 'shows magic item names' do
          allow(@char).to receive(:osr_inventory).and_return({ 'potion_healing' => 1 })
          rows = EquipmentHelper.inventory_display(@char)
          expect(rows.length).to eq 1
          expect(rows.first[:name]).to eq 'Potion of Healing'
          expect(rows.first[:category]).to eq 'magic_consumables'
        end
      end

      describe 'state_for_web' do
        it 'returns catalog when eligible' do
          allow(ReferenceData).to receive(:equipment_for_web).and_return({
            armor: [],
            weapons: [{ key: 'torch', name: 'Torch', cost: 1 }],
            missile_weapons: [],
            adventuring_gear: []
          })

          state = ShopHelper.state_for_web(@char)
          expect(state[:eligible]).to eq true
          expect(state[:gold]).to eq 1000
          expect(state[:catalog_sections]).not_to be_empty
        end

        it 'returns message when not eligible' do
          allow(@char).to receive(:is_approved?).and_return(false)
          state = ShopHelper.state_for_web(@char)
          expect(state[:eligible]).to eq false
          expect(state[:message]).to eq t('osr_rpg.shop_not_eligible')
        end
      end
    end
  end
end
