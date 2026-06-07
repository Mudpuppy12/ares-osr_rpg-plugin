module AresMUSH
  module OsrRpg
    describe 'Play mechanics' do
      before do
        @char = double('char',
                       name: 'Tester',
                       osr_class: 'fighter',
                       osr_level: 1,
                       osr_thac0: 19,
                       osr_hp: 10,
                       osr_hp_max: 10,
                       osr_ac: 0,
                       osr_gold: 100,
                       osr_inventory: {},
                       osr_saving_throws: { 'death' => 12 },
                       osr_thief_skills: { 'hide_in_shadows' => 3 },
                       osr_ability_scores: { 'str' => 14, 'dex' => 12 },
                       osr_spell_slots: { '1' => 1 },
                       osr_spell_slots_used: {},
                       osr_prepared_spells: {},
                       osr_spell_book: { '1' => ['Magic Missile'] },
                       osr_spell_tradition: 'magic_user',
                       osr_equipment: [])
        allow(@char).to receive(:update)
        allow(Leveling).to receive(:sheet_ready?).with(@char).and_return(true)
        allow(CommandHelpers).to receive(:sheet_applied?).with(@char).and_return(true)
      end

      describe 'Resources' do
        it 'adjusts HP' do
          expect(@char).to receive(:update).with(osr_hp: 8)
          Resources.adjust_hp(@char, -2)
        end

        it 'sets AC' do
          expect(@char).to receive(:update).with(osr_ac: 5)
          Resources.set_ac(@char, 5)
        end
      end

      describe 'Rolls.perform_roll' do
        it 'rolls attack with ascending AC' do
          allow(Global).to receive(:read_config).with('osr_rpg', 'ac_baseline').and_return(9)
          allow(Rolls).to receive(:rand).and_return(15)
          result = Rolls.perform_roll(@char, 'attack', ac: 0)
          expect(result[:hit]).to eq true
          expect(result[:needed]).to eq 10
        end
      end

      describe 'Spellcasting' do
        before do
          allow(@char).to receive(:osr_class).and_return('magic_user')
          allow(Tables).to receive(:casting_type).with('magic_user').and_return('arcane')
          allow(Tables).to receive(:spells_for_tradition).with('magic_user').and_return({ '1' => ['Magic Missile'] })
        end

        it 'prepares and casts a spell' do
          expect(@char).to receive(:update).with(hash_including(:osr_prepared_spells))
          prep = Spellcasting.prepare_spell(@char, 'Magic Missile')
          expect(prep[:spell]).to eq 'Magic Missile'

          allow(@char).to receive(:osr_prepared_spells).and_return({ '1' => ['Magic Missile'] })
          expect(@char).to receive(:update).with(hash_including(:osr_spell_slots_used))
          cast = Spellcasting.cast_spell(@char, 'Magic Missile')
          expect(cast[:spell]).to eq 'Magic Missile'
        end
      end

      describe 'StaffTools' do
        it 'looks up monster xp by hd' do
          allow(Global).to receive(:read_config).with('osr', 'monster_xp', 'by_hd').and_return({ '1' => 10, 'default' => 400 })
          expect(StaffTools.monster_xp(1)).to eq 10
        end
      end
    end
  end
end
