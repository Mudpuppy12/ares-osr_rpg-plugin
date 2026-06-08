module AresMUSH
  module OsrRpg
    describe 'Combat' do
      describe 'for_scene' do
        let(:scene) { double('scene', id: '42') }
        let(:record) { double('record') }
        let(:find_result) { double('find_result') }

        it 'returns existing combat record via indexed lookup' do
          expect(OsrRpgSceneCombat).to receive(:find).with(scene_id: '42').and_return(find_result)
          expect(find_result).to receive(:first).and_return(record)
          expect(OsrRpgSceneCombat).not_to receive(:create)
          expect(Combat.for_scene(scene)).to eq(record)
        end

        it 'creates a record when none exists' do
          expect(OsrRpgSceneCombat).to receive(:find).with(scene_id: '42').and_return(find_result)
          expect(find_result).to receive(:first).and_return(nil)
          expect(OsrRpgSceneCombat).to receive(:create).with(scene: scene, active: false, combatants: []).and_return(record)
          expect(Combat.for_scene(scene)).to eq(record)
        end

        it 'returns nil when scene is nil' do
          expect(Combat.for_scene(nil)).to be_nil
        end
      end
    end
  end
end
