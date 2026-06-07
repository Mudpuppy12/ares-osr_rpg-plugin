module AresMUSH
  module OsrRpg
    describe 'Leveling' do
      before do
        allow(Global).to receive(:read_config).and_call_original
        allow(Global).to receive(:read_config).with('osr_rpg', 'hp_per_level').and_return('max')
      end

      describe 'Tables.hp_gain' do
        it 'returns max die plus CON in max mode' do
          expect(Tables.hp_gain('d8', 1)).to eq(9)
        end

        it 'returns at least 1 HP' do
          expect(Tables.hp_gain('d6', -5)).to eq(1)
        end
      end

      describe 'Tables.hp_gain roll mode' do
        before do
          allow(Global).to receive(:read_config).with('osr_rpg', 'hp_per_level').and_return('roll')
        end

        it 'returns a value within roll range' do
          10.times do
            gain = Tables.hp_gain('d8', 1)
            expect(gain).to be_between(2, 9)
          end
        end
      end

      describe 'Leveling.eligible_for_levelup?' do
        before do
          @char = double('char',
                         osr_class: 'fighter',
                         osr_level: 1,
                         osr_xp: 2000,
                         osr_thac0: 19,
                         osr_ability_scores: { 'con' => 10 })
        end

        it 'allows level-up when XP meets threshold' do
          expect(Leveling.eligible_for_levelup?(@char)).to be_nil
        end

        it 'rejects when XP is too low' do
          allow(@char).to receive(:osr_xp).and_return(100)
          expect(Leveling.eligible_for_levelup?(@char)).to include('Insufficient XP')
        end

        it 'rejects without a finalized sheet' do
          allow(@char).to receive(:osr_thac0).and_return(nil)
          expect(Leveling.eligible_for_levelup?(@char)).to eq(t('osr_rpg.no_sheet_for_levelup'))
        end
      end

      describe 'Leveling.apply_level_up' do
        before do
          @char = double('char',
                         osr_class: 'fighter',
                         osr_level: 1,
                         osr_xp: 2000,
                         osr_thac0: 19,
                         osr_hp: 8,
                         osr_hp_max: 8,
                         osr_ability_scores: { 'con' => 10 })
          allow(@char).to receive(:update)
        end

        it 'increases level and HP' do
          result = Leveling.apply_level_up(@char)
          expect(result[:error]).to be_nil
          expect(result[:level]).to eq(2)
          expect(result[:hp_added]).to eq(8)
          expect(@char).to have_received(:update).with(hash_including(osr_level: 2, osr_hp: 16, osr_hp_max: 16))
        end
      end

      describe 'Leveling.award_xp' do
        it 'does not drop below zero' do
          char = double('char', osr_xp: 50)
          allow(char).to receive(:update)
          xp = Leveling.award_xp(char, -100)
          expect(xp).to eq(0)
        end
      end
    end
  end
end
