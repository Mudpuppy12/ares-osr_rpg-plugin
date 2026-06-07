module AresMUSH
  module OsrRpg
    class CastCmd
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
          result = Spellcasting.cast_spell(model, self.remainder)
          if result[:error]
            client.emit_failure result[:error]
          else
            msg = t('osr_rpg.spell_cast', name: model.name, spell: result[:spell], level: result[:level])
            client.emit_success msg
            if enactor.room
              enactor.room.emit_ooc msg
            end
          end
        end
      end
    end
  end
end
