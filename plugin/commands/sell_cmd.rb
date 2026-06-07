module AresMUSH
  module OsrRpg
    class SellCmd
      include CommandHandler
      include PlayCmdSupport

      def parse_args
        parse_play_target(allow_other: false)
        parts = self.remainder.to_s.strip.split(/\s+/)
        self.options[:qty] = 1
        if parts.length > 1 && parts.last =~ /^\d+$/
          self.options[:qty] = parts.last.to_i
          parts.pop
        end
        self.options[:item] = parts.join(' ')
      end

      def required_args
        [self.options[:item]]
      end

      def handle
        with_play_char do |model|
          result = EquipmentHelper.sell_item(model, self.options[:item], self.options[:qty])
          if result[:error]
            client.emit_failure result[:error]
          else
            client.emit_success t('osr_rpg.sell_success',
                                  item: result[:item],
                                  qty: result[:qty],
                                  credit: result[:credit],
                                  gold: result[:gold])
          end
        end
      end
    end
  end
end
