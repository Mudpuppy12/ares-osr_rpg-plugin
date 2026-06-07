module AresMUSH
  module OsrRpg
    class EquipmentListRequestHandler
      def handle(request)
        ReferenceData.equipment_for_web
      end
    end
  end
end
