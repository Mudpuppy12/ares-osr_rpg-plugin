module AresMUSH
  class OsrRpgSceneCombat < Ohm::Model
    include ObjectModel

    reference :scene, 'AresMUSH::Scene'
    attribute :active, :type => DataType::Boolean, :default => false
    attribute :combatants, :type => DataType::Array, :default => []

    index :scene
  end
end
