module AresMUSH
  module OsrRpg
    class EnsureStartingGoldRequestHandler
      def handle(request)
        error = Website.check_login(request)
        return error if error

        id = request.args['id']
        enactor = request.enactor
        char = Character.find_one_by_name(id)
        return { error: t('webportal.not_found') } unless char

        unless AresMUSH::Chargen.can_approve?(enactor)
          return { error: t('dispatcher.not_allowed') } if char != enactor

          lock_error = AresMUSH::Chargen.check_chargen_locked(char)
          return { error: lock_error } if lock_error
        end

        OsrRpg::Chargen.shop_data_for_web(char)
      end
    end
  end
end
