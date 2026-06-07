module AresMUSH
  module OsrRpg
    class ResetCmd
      include CommandHandler

      attr_accessor :name

      def parse_args
        if cmd.args.blank?
          self.name = enactor_name
        else
          allow = CommandHelpers.can_set_other?(enactor)
          self.name, _remainder = CommandHelpers.parse_target_first_arg(cmd.args, enactor_name, allow_target: allow)
        end
      end

      def check_can_set
        return nil if enactor_name == self.name
        return nil if CommandHelpers.can_set_other?(enactor)
        return t('dispatcher.not_allowed')
      end

      def check_chargen_locked
        return nil if CommandHelpers.can_set_other?(enactor) && enactor_name != self.name
        AresMUSH::Chargen.check_chargen_locked(enactor) if enactor_name == self.name
      end

      def handle
        ClassTargetFinder.with_a_character(self.name, client, enactor) do |model|
          OsrRpg::Chargen.reset_char(model)
          client.emit_success t('osr_rpg.reset_complete')
        end
      end
    end
  end
end
