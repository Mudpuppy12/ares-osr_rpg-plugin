module AresMUSH
  module OsrRpg
    class CheckCmd
      include CommandHandler
      include PlayCmdSupport

      def parse_args
        parse_play_target(allow_other: true)
      end

      def required_args
        [self.remainder]
      end

      def check_can_set
        return nil if enactor_name == self.name
        return nil if CommandHelpers.can_set_other?(enactor)
        return t('dispatcher.not_allowed')
      end

      def handle
        with_play_char do |model|
          ability = self.remainder.to_s.split(/\s+/).first
          result = Rolls.roll_ability_check(model, ability, self.options[:target])
          if result[:error]
            client.emit_failure result[:error]
          else
            client.emit_success result[:message]
          end
        end
      end
    end
  end
end
