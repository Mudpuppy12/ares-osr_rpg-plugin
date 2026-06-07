module AresMUSH
  module OsrRpg
    class AlignmentCmd
      include CommandHandler

      attr_accessor :name, :alignment

      def parse_args
        allow = CommandHelpers.can_set_other?(enactor)
        self.name, remainder = CommandHelpers.parse_target_first_arg(cmd.args, enactor_name, allow_target: allow)
        self.alignment = remainder ? remainder.strip : nil
      end

      def required_args
        [self.name, self.alignment]
      end

      def check_valid_alignment
        return nil if self.alignment.blank?
        return t('osr_rpg.invalid_alignment_value', alignment: self.alignment) unless Tables.alignments.include?(self.alignment)
        nil
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
          error = OsrRpg::Chargen.set_alignment(model, self.alignment)
          if error
            client.emit_failure error
          else
            client.emit_success t('osr_rpg.alignment_set', alignment: self.alignment)
          end
        end
      end
    end
  end
end
