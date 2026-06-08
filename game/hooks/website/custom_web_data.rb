module AresMUSH
  module Website
    def self.custom_sidebar_data(viewer)
      return {} unless Manage.is_extra_installed?('osr_rpg')

      { osr_rpg_enabled: true }
    end
  end
end
