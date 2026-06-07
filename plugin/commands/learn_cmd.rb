module AresMUSH
  module OsrRpg
    class LearnCmd
      include CommandHandler
      include PlayCmdSupport

      def parse_args
        parse_play_target(allow_other: false)
        if self.remainder =~ /^(\d+)[\s\/]+(.+)$/
          self.options[:level] = $1.to_i
          self.remainder = $2.strip
        end
      end

      def required_args
        [self.remainder]
      end

      def handle
        with_play_char do |model|
          level = self.options[:level] || model.osr_level
          result = Spellcasting.learn_spell_on_levelup(model, level, self.remainder)
          if result[:error]
            client.emit_failure result[:error]
          else
            client.emit_success t('osr_rpg.learn_spell_success', spell: result[:spell], level: result[:level])
          end
        end
      end
    end
  end
end
