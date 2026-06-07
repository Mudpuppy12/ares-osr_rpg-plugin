module AresMUSH
  module OsrRpg
    class ExploreCmd
      include CommandHandler
      include PlayCmdSupport

      def parse_args
        parse_play_target(allow_other: false)
      end

      def required_args
        [self.remainder]
      end

      def handle
        with_play_char do |model|
          result = ClassFeatures.roll_exploration(model, self.remainder)
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
