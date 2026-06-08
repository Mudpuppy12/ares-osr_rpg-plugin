module AresMUSH
  module Chargen
    def self.custom_app_review(char)
      if Manage.is_extra_installed?('osr_rpg')
        return OsrRpg.app_review(char)
      end

      nil
    end
  end
end
