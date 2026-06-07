module AresMUSH
  module OsrRpg
    class GearCmd
      include CommandHandler
      include PlayCmdSupport

      def parse_args
        parse_play_target(allow_other: true)
      end

      def check_can_view
        return nil if enactor_name == self.name
        return nil if CommandHelpers.can_manage_osr_rpg?(enactor)
        return nil if Global.read_config('osr_rpg', 'public_sheets')
        return t('osr_rpg.no_permission_to_view_sheet')
      end

      def handle
        with_play_char do |model|
          EquipmentHelper.migrate_character!(model)
          equipped = EquipmentHelper.gear_display(model)
          inventory = EquipmentHelper.inventory_display(model)
          gold = model.osr_gold || 0
          ac = Resources.current_ac(model)

          if equipped.empty? && inventory.empty?
            client.emit_success t('osr_rpg.gear_empty', name: model.name, gold: gold)
          else
            equipped_line = equipped.any? ? equipped.map { |g| g[:name] }.join(', ') : t('osr_rpg.gear_none_equipped')
            inventory_line = inventory.any? ? inventory.map { |i| i[:qty] > 1 ? "#{i[:name]} x#{i[:qty]}" : i[:name] }.join(', ') : t('osr_rpg.gear_none_carried')
            client.emit_success t('osr_rpg.gear_full',
                                  name: model.name,
                                  gold: gold,
                                  equipped: equipped_line,
                                  inventory: inventory_line,
                                  ac: ac)
          end
        end
      end
    end
  end
end
