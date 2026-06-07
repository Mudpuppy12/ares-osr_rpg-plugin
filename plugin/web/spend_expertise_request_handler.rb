module AresMUSH
  module OsrRpg
    class SpendExpertiseRequestHandler
      def handle(request)
        error = Website.check_login(request)
        return { error: error } if error

        enactor = request.enactor
        allocations = request.args['allocations'] || {}
        return { error: t('osr_rpg.skills_args_required') } if allocations.blank?

        errors = Chargen.spend_expertise(enactor, allocations)
        return { error: errors.join(' ') } if errors.any?

        {
          sheet: Chargen.build_sheet_display(enactor),
          message: t('osr_rpg.skills_set',
                     results: allocations.map { |k, v| "#{k}=#{v}" }.join(', '),
                     unspent: enactor.osr_thief_expertise_unspent || 0)
        }
      end
    end
  end
end
