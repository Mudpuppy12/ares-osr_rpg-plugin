module AresMUSH
  module OsrRpg
    class LevelUpRequestHandler
      def handle(request)
        error = Website.check_login(request)
        return error if error

        char = request.enactor
        return { error: t('webportal.not_found') } unless char

        unless char.is_approved?
          return { error: t('osr_rpg.must_be_approved_to_level') }
        end

        result = Leveling.apply_level_up(char)
        return { error: result[:error] } if result[:error]

        sheet = Chargen.build_sheet_display(char)
        {
          level: result[:level],
          hp_added: result[:hp_added],
          hp: result[:hp],
          hp_max: result[:hp_max],
          sheet: sheet
        }
      end
    end
  end
end
