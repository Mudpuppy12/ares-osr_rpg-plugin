module AresMUSH
  module OsrRpg
    class TreasureCmd
      include CommandHandler

      attr_accessor :table_key

      def parse_args
        self.table_key = cmd.args.to_s.strip.presence || 'dungeon_loot'
      end

      def check_can_manage
        return nil if CommandHelpers.can_manage_osr_rpg?(enactor)
        return t('dispatcher.not_allowed')
      end

      def handle
        result = StaffTools.roll_treasure(self.table_key)
        if result[:error]
          client.emit_failure result[:error]
        else
          client.emit_success result[:message]
        end
      end
    end
  end
end
