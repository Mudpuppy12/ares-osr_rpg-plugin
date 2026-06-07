module AresMUSH
  module OsrRpg
    class SceneCombatRequestHandler
      def handle(request)
        scene = Scene[request.args['id']]
        error = Rolls.validate_scene_request(request, scene)
        return error if error

        action = request.args['action'].to_s
        enactor = request.enactor

        case action
        when 'get'
          record = Combat.for_scene(scene)
          return Combat.summary(record)
        when 'start'
          return { error: t('dispatcher.not_allowed') } unless CommandHelpers.can_manage_osr_rpg?(enactor)
          Combat.start_combat(scene, enactor)
          Combat.summary(Combat.for_scene(scene))
        when 'end'
          return { error: t('dispatcher.not_allowed') } unless CommandHelpers.can_manage_osr_rpg?(enactor)
          Combat.end_combat(scene, enactor)
          Combat.summary(Combat.for_scene(scene))
        when 'join'
          result = Combat.join_combat(scene, enactor)
          return result if result[:error]
          Combat.summary(Combat.for_scene(scene))
        when 'damage'
          return { error: t('dispatcher.not_allowed') } unless CommandHelpers.can_manage_osr_rpg?(enactor)
          result = Combat.apply_damage(scene, request.args['target'], request.args['amount'].to_i)
          return result if result[:error]
          Combat.summary(Combat.for_scene(scene))
        when 'heal'
          return { error: t('dispatcher.not_allowed') } unless CommandHelpers.can_manage_osr_rpg?(enactor)
          result = Combat.apply_heal(scene, request.args['target'], request.args['amount'].to_i)
          return result if result[:error]
          Combat.summary(Combat.for_scene(scene))
        when 'init'
          result = Combat.reroll_initiative(scene, request.args['target'])
          return result if result[:error]
          Combat.summary(Combat.for_scene(scene))
        when 'add_npc'
          return { error: t('dispatcher.not_allowed') } unless CommandHelpers.can_manage_osr_rpg?(enactor)
          record = Combat.for_scene(scene)
          Combat.start_combat(scene, enactor) unless record.active
          result = Combat.add_npc(scene, request.args['template'], request.args['label'])
          return result if result[:error]
          Combat.summary(Combat.for_scene(scene))
        else
          { error: t('osr_rpg.invalid_combat_action', action: action) }
        end
      end
    end
  end
end
