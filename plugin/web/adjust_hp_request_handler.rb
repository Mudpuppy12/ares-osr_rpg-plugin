module AresMUSH
  module OsrRpg
    class AdjustHpRequestHandler
      def handle(request)
        error = Website.check_login(request)
        return { error: error } if error

        enactor = request.enactor
        char_name = request.args['name'] || enactor.name
        char = Character.named(char_name)
        return { error: t('webportal.not_found') } unless char
        return { error: t('dispatcher.not_allowed') } unless AresCentral.is_alt?(char, enactor) || CommandHelpers.can_manage_osr_rpg?(enactor)
        return { error: t('osr_rpg.no_sheet_for_levelup') } unless Leveling.sheet_ready?(char)

        amount = request.args['amount'].to_i
        result = Resources.adjust_hp(char, amount)
        {
          hp: result[:hp],
          hp_max: result[:hp_max],
          sheet: Chargen.build_sheet_display(char)
        }
      end
    end
  end
end
