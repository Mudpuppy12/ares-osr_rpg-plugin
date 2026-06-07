module AresMUSH
  module OsrRpg
    class ThiefCmd
      include CommandHandler

      attr_accessor :name, :pairs

      def parse_args
        args = cmd.args.to_s
        allow = CommandHelpers.can_set_other?(enactor)

        if allow && args =~ /^[^\/=]+\/.+=/
          self.name, remainder = args.split('/', 2)
          self.name = self.name.strip
        else
          self.name = enactor_name
          remainder = args
        end
        self.pairs = Tables.parse_key_value_pairs(remainder)
      end

      def check_pairs
        return t('osr_rpg.thief_args_required') if self.pairs.empty?
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
          errors = OsrRpg::Chargen.set_thief_allocations(model, self.pairs)
          if errors.any?
            client.emit_failure errors.join('%r')
          else
            lines = self.pairs.map { |skill, pts| "#{skill}=#{pts}" }
            client.emit_success t('osr_rpg.thief_set', results: lines.join(', '))
          end
        end
      end
    end
  end
end
