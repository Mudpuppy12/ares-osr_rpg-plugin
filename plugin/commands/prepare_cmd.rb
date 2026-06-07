module AresMUSH
  module OsrRpg
    class PrepareCmd
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
          result = Spellcasting.prepare_spell(model, self.remainder)
          if result[:error]
            client.emit_failure result[:error]
          else
            client.emit_success t('osr_rpg.spell_prepared', spell: result[:spell], level: result[:level])
          end
        end
      end
    end
  end
end
