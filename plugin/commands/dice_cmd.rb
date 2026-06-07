module AresMUSH
  module OsrRpg
    class DiceCmd
      include CommandHandler
      include PlayCmdSupport

      def parse_args
        parse_play_target(allow_other: false)
        self.remainder = cmd.args.to_s.strip if self.remainder.blank? && cmd.args.present?
      end

      def required_args
        [self.remainder]
      end

      def handle
        with_play_char do |model|
          result = Rolls.roll_generic(model.name, self.remainder)
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
