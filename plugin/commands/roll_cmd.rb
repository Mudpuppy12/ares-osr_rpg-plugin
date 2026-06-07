module AresMUSH
  module OsrRpg
    class RollCmd
      include CommandHandler

      attr_accessor :name, :ability

      def parse_args
        allow = CommandHelpers.can_set_other?(enactor)
        self.name, remainder = CommandHelpers.parse_target_first_arg(cmd.args, enactor_name, allow_target: allow)
        self.ability = remainder ? remainder.strip.downcase : nil
      end

      def check_valid_ability
        return nil if self.ability.blank?
        return t('osr_rpg.invalid_ability', ability: self.ability) unless Tables.abilities.include?(self.ability)
        nil
      end

      def check_can_set
        return nil if enactor_name == self.name
        return nil if CommandHelpers.can_set_other?(enactor)
        return t('dispatcher.not_allowed')
      end

      def check_chargen_locked
        return nil if CommandHelpers.can_set_other?(enactor) && enactor_name != self.name
        AresMUSH::Chargen.check_chargen_locked(enactor) if enactor_name == self.name
      end

      def handle
        ClassTargetFinder.with_a_character(self.name, client, enactor) do |model|
          to_roll = self.ability ? [self.ability] : nil
          rolled = OsrRpg::Chargen.roll_abilities(model, to_roll)
          roll_count = model.osr_ability_roll_count || 0
          lines = rolled.map { |ab, score| "#{ab.upcase} #{score}" }
          msg = self.ability ? t('osr_rpg.ability_rolled', results: lines.join(', '), roll_count: roll_count) : t('osr_rpg.abilities_rolled', results: lines.join(', '), roll_count: roll_count)
          client.emit_success msg
        end
      end
    end
  end
end
