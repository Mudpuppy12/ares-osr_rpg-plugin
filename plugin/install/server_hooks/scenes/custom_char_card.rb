module AresMUSH
  module Scenes
    def self.custom_char_card_fields(char, viewer)
      return nil unless Manage.is_extra_installed?('osr_rpg')

      sheet = OsrRpg::Rolls.scene_sheet(char)
      return nil unless sheet

      { osr_rpg: sheet }
    end
  end
end
