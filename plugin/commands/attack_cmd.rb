module AresMUSH
  module OsrRpg
    class AttackCmd
      include CommandHandler
      include PlayCmdSupport

      def parse_args
        parse_play_target(allow_other: true)
      end

      def check_can_set
        return nil if enactor_name == self.name
        return nil if CommandHelpers.can_set_other?(enactor)
        return t('dispatcher.not_allowed')
      end

      def handle
        with_play_char do |model|
          result = Rolls.roll_attack(model, target_ac: self.options[:ac])
          client.emit_success result[:message]
        end
      end
    end
  end
end
