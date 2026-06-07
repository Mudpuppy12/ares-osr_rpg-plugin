module AresMUSH
  class Character
    attribute :ose_class
    attribute :ose_level, :type => DataType::Integer, :default => 1
    attribute :ose_xp, :type => DataType::Integer, :default => 0
    attribute :ose_hp, :type => DataType::Integer
    attribute :ose_hp_max, :type => DataType::Integer
    attribute :ose_alignment
    attribute :ose_ability_scores, :type => DataType::Hash, :default => {}
    attribute :ose_saving_throws, :type => DataType::Hash, :default => {}
    attribute :ose_spell_slots, :type => DataType::Hash, :default => {}
    attribute :ose_thief_skills, :type => DataType::Hash, :default => {}
    attribute :ose_thac0, :type => DataType::Integer
    attribute :ose_starting_gold, :type => DataType::Integer
    attribute :ose_xp_bonus, :type => DataType::Integer, :default => 0
  end
end
