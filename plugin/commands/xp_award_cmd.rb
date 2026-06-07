module AresMUSH
  module OsrRpg
    class XpAwardCmd
      include CommandHandler

      attr_accessor :name, :xp

      def parse_args
        args = cmd.parse_args(ArgParser.arg1_equals_arg2)
        self.name = trim_arg(args.arg1)
        self.xp = integer_arg(args.arg2)
        if cmd.switch.to_s.include?('remove') && self.xp
          self.xp = 0 - self.xp
        end
      end

      def required_args
        [self.name, self.xp]
      end

      def check_xp
        return nil if !self.xp
        return t('osr_rpg.invalid_xp_award') if self.xp == 0
        nil
      end

      def check_can_award
        return nil if Leveling.can_manage_xp?(enactor)
        return t('dispatcher.not_allowed')
      end

      def handle
        ClassTargetFinder.with_a_character(self.name, client, enactor) do |model|
          if (model.osr_xp || 0) + self.xp < 0
            client.emit_failure t('osr_rpg.invalid_xp_award')
            return
          end

          result = Leveling.award_xp(model, self.xp)

          if self.xp < 0
            Global.logger.info "#{result[:awarded]} OSR XP removed by #{enactor_name} from #{model.name} (total #{result[:new_total]})"
            client.emit_success t('osr_rpg.xp_removed', name: model.name, xp: -self.xp)
          else
            Global.logger.info "#{result[:awarded]} OSR XP awarded by #{enactor_name} to #{model.name} (#{result[:base]} base, total #{result[:new_total]})"
            if result[:awarded] == result[:base]
              client.emit_success t('osr_rpg.xp_awarded', name: model.name, xp: result[:awarded])
            else
              client.emit_success t('osr_rpg.xp_awarded_with_bonus',
                                    name: model.name,
                                    awarded: result[:awarded],
                                    base: result[:base],
                                    bonus_percent: result[:bonus_percent])
            end
          end
        end
      end
    end
  end
end
