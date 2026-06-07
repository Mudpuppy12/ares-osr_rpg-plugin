module AresMUSH
  module OsrRpg
    class ClassCmd
      include CommandHandler

      attr_accessor :name, :class_key

      def parse_args
        allow = CommandHelpers.can_set_other?(enactor)
        self.name, remainder = CommandHelpers.parse_target_first_arg(cmd.args, enactor_name, allow_target: allow)
        self.class_key = remainder ? remainder.strip.downcase.gsub(/\s+/, '_') : nil
      end

      def required_args
        [self.name, self.class_key]
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
          error = OsrRpg::Chargen.set_class(model, self.class_key)
          if error
            client.emit_failure error
          else
            cfg = Tables.class_config(self.class_key)
            client.emit_success t('osr_rpg.class_set', class: Tables.val(cfg, 'name'), key: self.class_key)
          end
        end
      end
    end
  end
end
