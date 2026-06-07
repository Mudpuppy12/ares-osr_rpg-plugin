module AresMUSH
  module OsrRpg
    class SceneRollRequestHandler
      def handle(request)
        scene = Scene[request.args['id']]
        error = Rolls.validate_scene_request(request, scene)
        return error if error

        resolved = Rolls.resolve_sender(request)
        return resolved if resolved[:error]

        sender = resolved[:sender]
        return { error: t('osr_rpg.no_sheet_for_levelup') } unless Leveling.sheet_ready?(sender)

        roll_type = request.args['roll_type'].to_s
        options = {
          ac: request.args['target_ac'] || request.args['ac'],
          category: request.args['save_category'],
          skill: request.args['skill'],
          ability: request.args['ability'],
          target: request.args['target'],
          dice_string: request.args['dice_string'],
          hd: request.args['hd'],
          exploration_skill: request.args['exploration_skill']
        }
        result = Rolls.perform_roll(sender, roll_type, options)
        return result if result[:error]

        Rolls.emit_to_scene(scene, result[:message])
        result.except(:message)
      end
    end
  end
end
