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
        result = case roll_type
                 when 'attack'
                   Rolls.roll_attack(sender)
                 when 'save'
                   Rolls.roll_save(sender, request.args['save_category'])
                 when 'skill'
                   Rolls.roll_thief_skill(sender, request.args['skill'])
                 when 'ability'
                   Rolls.roll_ability_check(sender, request.args['ability'], request.args['target'])
                 when 'generic'
                   Rolls.roll_generic(sender.name, request.args['dice_string'])
                 else
                   { error: t('osr_rpg.invalid_roll_type', type: roll_type) }
                 end

        return result if result[:error]

        Rolls.emit_to_scene(scene, result[:message])
        result.except(:message)
      end
    end
  end
end
