module AresMUSH
  module OsrRpg
    class SceneSheetRequestHandler
      def handle(request)
        scene = Scene[request.args['id']]
        error = Rolls.validate_scene_request(request, scene)
        return error if error

        resolved = Rolls.resolve_sender(request)
        return resolved if resolved[:error]

        sender = resolved[:sender]
        sheet = Rolls.scene_sheet(sender)
        return { error: t('osr_rpg.no_sheet_for_levelup') } unless sheet

        { sheet: sheet }
      end
    end
  end
end
