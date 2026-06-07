module AresMUSH
  module OsrRpg
    class HpCmd
      include CommandHandler

      attr_accessor :name, :amount, :current, :maximum, :mode

      def parse_args
        self.mode = cmd.switch.to_s.include?('set') ? :set : :adjust
        if self.mode == :set
          args = cmd.parse_args(ArgParser.arg1_equals_arg2)
          self.name = trim_arg(args.arg1)
          parts = args.arg2.to_s.split('/', 2)
          self.current = parts[0].to_i
          self.maximum = parts[1] ? parts[1].to_i : nil
        else
          allow = CommandHelpers.can_manage_osr_rpg?(enactor)
          self.name, remainder = CommandHelpers.parse_target_first_arg(cmd.args, enactor_name, allow_target: allow)
          self.amount = remainder.to_i
          self.amount = cmd.args.to_i if self.amount == 0 && cmd.args.present? && cmd.args !~ /\//
        end
      end

      def check_can_manage
        return nil if enactor_name == self.name
        return nil if CommandHelpers.can_manage_osr_rpg?(enactor)
        return t('dispatcher.not_allowed')
      end

      def handle
        ClassTargetFinder.with_a_character(self.name, client, enactor) do |model|
          error = CommandHelpers.check_sheet_ready(model)
          if error
            client.emit_failure error
            return
          end

          if self.mode == :set
            unless CommandHelpers.can_manage_osr_rpg?(enactor)
              client.emit_failure t('dispatcher.not_allowed')
              return
            end
            result = Resources.set_hp(model, self.current, self.maximum)
            client.emit_success t('osr_rpg.hp_set', name: model.name, hp: result[:hp], hp_max: result[:hp_max])
          else
            result = Resources.adjust_hp(model, self.amount)
            key = self.amount >= 0 ? 'osr_rpg.hp_healed' : 'osr_rpg.hp_damaged'
            client.emit_success t(key, name: model.name, amount: self.amount.abs, hp: result[:hp], hp_max: result[:hp_max])
          end
        end
      end
    end
  end
end
