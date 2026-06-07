module AresMUSH
  module OsrRpg
    class EquipCmd
      include CommandHandler
      include PlayCmdSupport

      def parse_args
        parse_play_target(allow_other: false)
        self.options[:remove] = cmd.switch.to_s.include?('unequip')
      end

      def required_args
        [self.remainder]
      end

      def handle
        with_play_char do |model|
          result = if self.options[:remove]
                     EquipmentHelper.unequip_item(model, self.remainder)
                   else
                     EquipmentHelper.equip_item(model, self.remainder)
                   end
          if result[:error]
            client.emit_failure result[:error]
          else
            client.emit_success t('osr_rpg.equip_updated', ac: result[:ac])
          end
        end
      end
    end
  end
end
