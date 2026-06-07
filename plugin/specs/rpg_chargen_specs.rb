module AresMUSH
  module Rpg
    describe 'Chargen' do
      before do
        @char = double('char')
        allow(@char).to receive(:update)
        allow(@char).to receive(:ose_starting_gold).and_return(nil)
      end

      describe 'validate' do
        it 'requires class' do
          alerts = Chargen.validate(nil, 'Law', { 'str' => 10 }, {})
          expect(alerts).to include(t('rpg.class_not_set'))
        end

        it 'rejects assassin with Lawful alignment' do
          scores = { 'str' => 10, 'dex' => 13, 'con' => 10, 'int' => 10, 'wis' => 10, 'cha' => 10 }
          alerts = Chargen.validate('assassin', 'Law', scores, {})
          expect(alerts).to include(t('rpg.invalid_alignment', alignment: 'Law'))
        end

        it 'accepts paladin with Lawful alignment' do
          scores = { 'str' => 13, 'dex' => 10, 'con' => 10, 'int' => 10, 'wis' => 13, 'cha' => 10 }
          alerts = Chargen.validate('paladin', 'Law', scores, {})
          expect(alerts).not_to include(t('rpg.invalid_alignment', alignment: 'Law'))
        end

        it 'validates thief expertise points' do
          scores = { 'str' => 10, 'dex' => 13, 'con' => 10, 'int' => 10, 'wis' => 10, 'cha' => 10 }
          skills = { 'hide_in_shadows' => 2, 'move_silently' => 1 }
          alerts = Chargen.validate('thief', 'Neutrality', scores, skills)
          expect(alerts).to include(t('rpg.thief_points_wrong', points: 4, spent: 3))
        end
      end
    end
  end
end
