module AresMUSH
  module Profile
    class CustomCharFields
      def self.osr_rpg_enabled?
        Manage.is_extra_installed?('osr_rpg')
      end

      def self.get_fields_for_viewing(char, viewer)
        return {} unless osr_rpg_enabled?

        sheet = OsrRpg.get_sheet_for_web_viewing(char, viewer)
        return {} unless sheet

        { osr_rpg: sheet }
      end

      def self.get_fields_for_editing(char, viewer)
        get_fields_for_viewing(char, viewer)
      end

      def self.get_fields_for_chargen(char)
        return {} unless osr_rpg_enabled?

        sheet = OsrRpg.get_sheet_for_web_editing(char, char)
        return {} unless sheet

        blurb = Website.format_markdown_for_html(Global.read_config('osr_rpg', 'osr_rpg_blurb'))
        { osr_rpg: sheet.merge('osr_rpg_blurb' => blurb) }
      end

      def self.save_fields_from_chargen(char, chargen_data)
        return [] unless osr_rpg_enabled?

        custom = chargen_data['custom'] || {}
        data = custom['osr_rpg']
        return [] if data.blank?

        errors = OsrRpg::Chargen.save_char(char, data)
        errors.is_a?(Array) ? errors : []
      end

      def self.save_fields_from_profile_edit(char, char_data)
        []
      end

      def self.save_fields_from_profile_edit2(char, enactor, char_data)
        CustomCharFields.save_fields_from_profile_edit(char, char_data)
      end
    end
  end
end
