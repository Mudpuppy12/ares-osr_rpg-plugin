module AresMUSH
  module OsrRpg
    class BackstabCmd
      include CommandHandler
      include PlayCmdSupport

      def parse_args
        parse_play_target(allow_other: false)
      end

      def handle
        with_play_char do |model|
          result = ClassFeatures.roll_backstab(model, self.options[:ac])
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
