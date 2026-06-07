module AresMUSH
  class Character
    attribute :osr_class
    attribute :osr_level, :type => DataType::Integer, :default => 1
    attribute :osr_xp, :type => DataType::Integer, :default => 0
    attribute :osr_hp, :type => DataType::Integer
    attribute :osr_hp_max, :type => DataType::Integer
    attribute :osr_alignment
    attribute :osr_ability_scores, :type => DataType::Hash, :default => {}
    attribute :osr_saving_throws, :type => DataType::Hash, :default => {}
    attribute :osr_spell_slots, :type => DataType::Hash, :default => {}
    attribute :osr_thief_skills, :type => DataType::Hash, :default => {}
    attribute :osr_thac0, :type => DataType::Integer
    attribute :osr_starting_gold, :type => DataType::Integer
    attribute :osr_xp_bonus, :type => DataType::Integer, :default => 0
    attribute :osr_ability_roll_count, :type => DataType::Integer, :default => 0
    attribute :osr_spell_book, :type => DataType::Hash, :default => {}
    attribute :osr_spell_tradition
    attribute :osr_thief_expertise_unspent, :type => DataType::Integer, :default => 0
  end
end
