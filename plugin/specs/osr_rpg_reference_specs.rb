module AresMUSH
  module OsrRpg
    describe 'Reference data' do
      before do
        allow(Global).to receive(:read_config).and_call_original
        allow(Global).to receive(:read_config).with('osr', 'spells').and_return({
          'cleric' => { '1' => ['Cure Light Wounds', 'Light'] },
          'magic_user' => { '1' => ['Magic Missile'] }
        })
        allow(Global).to receive(:read_config).with('osr', 'spell_details', 'cleric').and_return({
          '1' => {
            'cure_light_wounds' => {
              'name' => 'Cure Light Wounds',
              'description' => 'Heals 1d6+1 HP.',
              'reversal' => 'Cause Light Wounds'
            },
            'light' => { 'name' => 'Light', 'description' => '15 radius light.' }
          }
        })
        allow(Global).to receive(:read_config).with('osr', 'spell_details', 'magic_user').and_return({
          '1' => { 'magic_missile' => { 'name' => 'Magic Missile', 'description' => '1d6+1 unerring damage.' } }
        })
        allow(Global).to receive(:read_config).with('osr', 'equipment').and_return({
          'armor' => { 'leather' => { 'name' => 'Leather', 'ac' => 7, 'cost' => 20 } },
          'weapons' => { 'sword' => { 'name' => 'Sword', 'damage' => '1d8', 'cost' => 10 } },
          'missile_weapons' => { 'short_bow' => { 'name' => 'Short Bow', 'damage' => '1d6', 'cost' => 15 } },
          'adventuring_gear' => { 'torch' => { 'name' => 'Torch', 'cost' => 1 } }
        })
        allow(Global).to receive(:read_config).with('osr_rpg', 'spells_blurb').and_return('Spell reference.')
        allow(Global).to receive(:read_config).with('osr_rpg', 'equipment_blurb').and_return('Equipment reference.')
        allow(Website).to receive(:format_markdown_for_html) { |text| "<p>#{text}</p>" }
      end

      describe 'ReferenceData.spells_for_web' do
        it 'returns traditions and grouped spells' do
          result = ReferenceData.spells_for_web('cleric')
          expect(result[:traditions].map { |t| t[:key] }).to include('cleric')
          expect(result[:spells_by_level].first[:spells].map { |s| s[:name] }).to include('Cure Light Wounds')
          expect(result[:spells_blurb]).to include('Spell reference')
        end
      end

      describe 'Tables.spell_detail' do
        it 'reads nested spell details beyond Global.read_config depth' do
          allow(Global).to receive(:read_config).with('osr', 'spell_details', 'cleric').and_return({
            '1' => { 'cure_light_wounds' => { 'name' => 'Cure Light Wounds', 'description' => 'Heals.' } }
          })
          entry = Tables.spell_detail('cleric', '1', 'cure_light_wounds')
          expect(entry['name']).to eq 'Cure Light Wounds'
        end

        it 'normalizes spell keys for URLs' do
          expect(Tables.spell_detail_key("Blindness/Deafness")).to eq 'blindnessdeafness'
          expect(Tables.spell_detail_key("Silence 15' Radius")).to eq 'silence_15_radius'
        end
      end

      describe 'ReferenceData.format_spell_text' do
        it 'capitalizes the first letter' do
          expect(ReferenceData.format_spell_text('heals 1d6+1 HP.')).to eq 'Heals 1d6+1 HP.'
        end
      end

      describe 'ReferenceData.spell_detail_for_web' do
        it 'returns spell detail with reversal' do
          allow(Global).to receive(:read_config).with('osr', 'spell_details', 'cleric').and_return({
            '1' => {
              'cure_light_wounds' => {
                'name' => 'Cure Light Wounds',
                'description' => 'Heals 1d6+1 HP.',
                'reversal' => 'Cause Light Wounds'
              }
            }
          })
          result = ReferenceData.spell_detail_for_web('cleric', '1', 'cure_light_wounds')
          expect(result[:name]).to eq 'Cure Light Wounds'
          expect(result[:description]).to include('1d6+1')
          expect(result[:reversal]).to eq 'Cause Light Wounds'
        end

        it 'returns error for unknown spell' do
          allow(Global).to receive(:read_config).with('osr', 'spell_details', 'cleric').and_return({ '1' => {} })
          result = ReferenceData.spell_detail_for_web('cleric', '1', 'missing')
          expect(result[:error]).not_to be_nil
        end
      end

      describe 'ReferenceData.equipment_for_web' do
        it 'returns categorized equipment lists' do
          result = ReferenceData.equipment_for_web
          expect(result[:armor].first[:name]).to eq 'Leather'
          expect(result[:weapons].first[:damage]).to eq '1d8'
          expect(result[:missile_weapons].first[:name]).to eq 'Short Bow'
          expect(result[:adventuring_gear].first[:name]).to eq 'Torch'
          expect(result[:equipment_blurb]).to include('Equipment reference')
        end
      end

      describe 'request handlers' do
        it 'handles spells list request' do
          request = double('request', args: { tradition: 'cleric' })
          result = SpellsListRequestHandler.new.handle(request)
          expect(result[:spells_by_level]).not_to be_empty
        end

        it 'handles spell detail request' do
          request = double('request', args: { tradition: 'cleric', level: '1', name: 'cure_light_wounds' })
          result = SpellDetailRequestHandler.new.handle(request)
          expect(result[:name]).to eq 'Cure Light Wounds'
        end

        it 'handles equipment list request' do
          request = double('request', args: {})
          result = EquipmentListRequestHandler.new.handle(request)
          expect(result[:armor]).not_to be_empty
        end
      end
    end
  end
end
