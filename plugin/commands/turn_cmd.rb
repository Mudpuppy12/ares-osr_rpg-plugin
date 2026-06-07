module AresMUSH
  module OsrRpg
    class TurnCmd
      include CommandHandler
      include PlayCmdSupport

      def parse_args
        parse_play_target(allow_other: false)
        self.options[:hd] ||= self.remainder.to_i if self.remainder.present?
      end

      def handle
        with_play_char do |model|
          hd = self.options[:hd] || 1
          result = ClassFeatures.roll_turn(model, hd)
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
