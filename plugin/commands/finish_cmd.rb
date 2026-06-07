module AresMUSH
  module OsrRpg
    class FinishCmd
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
          alerts = OsrRpg::Chargen.finish_char(model)
          if alerts.any?
            client.emit_failure alerts.join('%r')
          else
            client.emit_success t('osr_rpg.finish_complete')
            template = SheetTemplate.new(model)
            client.emit template.render
          end
        end
      end
    end
  end
end
