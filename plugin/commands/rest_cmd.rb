module AresMUSH
  module OsrRpg
    class RestCmd
      include CommandHandler
      include PlayCmdSupport

      def parse_args
        parse_play_target(allow_other: true)
      end

      def check_can_rest_other
        return nil if enactor_name == self.name
        return nil if CommandHelpers.can_manage_osr_rpg?(enactor)
        return t('dispatcher.not_allowed')
      end

      def handle
        with_play_char do |model|
          Spellcasting.rest_spells(model)
          client.emit_success t('osr_rpg.rest_complete', name: model.name)
        end
      end
    end
  end
end
