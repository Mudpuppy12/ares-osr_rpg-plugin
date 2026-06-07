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
          gear = EquipmentHelper.gear_display(model)
          if gear.empty?
            client.emit_success t('osr_rpg.gear_empty', name: model.name)
          else
            lines = gear.map { |g| g[:name] }.join(', ')
            client.emit_success t('osr_rpg.gear_list', name: model.name, gear: lines, ac: Resources.current_ac(model))
          end
        end
      end
    end
  end
end
