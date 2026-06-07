module AresMUSH
  module OsrRpg
    class EquipRequestHandler
      def handle(request)
        error = Website.check_login(request)
        return { error: error } if error

        enactor = request.enactor
        return { error: t('osr_rpg.no_sheet_for_levelup') } unless Leveling.sheet_ready?(enactor)

        action = request.args['action'].to_s
        item = request.args['item'].to_s
        return { error: t('osr_rpg.invalid_equipment', item: item) } if item.blank?

        result = case action
                 when 'equip'
                   EquipmentHelper.equip_item(enactor, item)
                 when 'unequip'
                   EquipmentHelper.unequip_item(enactor, item)
                 else
                   { error: t('osr_rpg.invalid_equip_action', action: action) }
                 end
        return result if result[:error]

        {
          sheet: Chargen.build_sheet_display(enactor),
          ac: result[:ac],
          message: t('osr_rpg.equip_updated', ac: result[:ac])
        }
      end
    end
  end
end
