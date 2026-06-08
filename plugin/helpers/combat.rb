module AresMUSH
  module OsrRpg
    module Combat
      def self.for_scene(scene)
        return nil unless scene
        record = OsrRpgSceneCombat.find(scene_id: scene.id).first
        return record if record

        OsrRpgSceneCombat.create(scene: scene, active: false, combatants: [])
      end

      def self.new_combatant_id
        "#{Time.now.to_f}-#{rand(10_000)}"
      end

      def self.combatants(record)
        record.combatants || []
      end

      def self.save_combatants(record, list)
        record.update(combatants: list)
        list
      end

      def self.start_combat(scene, enactor)
        record = for_scene(scene)
        record.update(active: true, combatants: [])
        emit_scene(scene, t('osr_rpg.combat_started', name: enactor.name))
        record
      end

      def self.end_combat(scene, enactor)
        record = for_scene(scene)
        record.update(active: false, combatants: [])
        emit_scene(scene, t('osr_rpg.combat_ended', name: enactor.name))
        record
      end

      def self.join_combat(scene, char)
        record = for_scene(scene)
        return { error: t('osr_rpg.combat_not_active') } unless record.active

        list = combatants(record).dup
        return { error: t('osr_rpg.combat_already_joined') } if list.any? { |c| c['name'] == char.name }

        dex = char.osr_ability_scores['dex'] || char.osr_ability_scores[:dex]
        init = rand(1..20) + Tables.ability_modifier(dex.to_i)
        list << {
          'id' => new_combatant_id,
          'name' => char.name,
          'char_id' => char.id,
          'is_npc' => false,
          'initiative' => init,
          'hp' => char.osr_hp || 0,
          'hp_max' => char.osr_hp_max || 0,
          'ac' => Resources.current_ac(char)
        }
        save_combatants(record, list)
        { combatant: list.last, initiative: init }
      end

      def self.add_npc(scene, template_key, label = nil)
        record = for_scene(scene)
        return { error: t('osr_rpg.combat_not_active') } unless record.active

        templates = Global.read_config('osr', 'npc_templates') || {}
        tpl = templates[template_key.to_s] || templates[template_key.to_sym]
        return { error: t('osr_rpg.invalid_npc_template', template: template_key) } unless tpl

        list = combatants(record).dup
        name = label.presence || tpl['name'] || template_key.to_s.titleize
        list << {
          'id' => new_combatant_id,
          'name' => name,
          'char_id' => nil,
          'is_npc' => true,
          'template' => template_key.to_s,
          'initiative' => rand(1..20),
          'hp' => tpl['hp'].to_i,
          'hp_max' => tpl['hp'].to_i,
          'ac' => tpl['ac'].to_i,
          'hd' => tpl['hd'].to_i,
          'thac0' => tpl['thac0'].to_i,
          'xp' => tpl['xp'].to_i
        }
        save_combatants(record, list)
        { combatant: list.last }
      end

      def self.find_combatant(record, name)
        combatants(record).find { |c| c['name'].to_s.downcase == name.to_s.downcase }
      end

      def self.apply_damage(scene, target_name, amount)
        record = for_scene(scene)
        return { error: t('osr_rpg.combat_not_active') } unless record.active

        list = combatants(record).dup
        c = list.find { |x| x['name'].to_s.downcase == target_name.to_s.downcase }
        return { error: t('osr_rpg.combatant_not_found', name: target_name) } unless c

        c['hp'] = [c['hp'].to_i - amount.to_i, 0].max
        if c['char_id'].present? && !c['is_npc']
          char = Character[c['char_id']]
          Resources.adjust_hp(char, -amount.to_i) if char
        end
        save_combatants(record, list)
        emit_scene(scene, t('osr_rpg.combat_damage', name: c['name'], amount: amount, hp: c['hp']))
        { combatant: c }
      end

      def self.apply_heal(scene, target_name, amount)
        record = for_scene(scene)
        return { error: t('osr_rpg.combat_not_active') } unless record.active

        list = combatants(record).dup
        c = list.find { |x| x['name'].to_s.downcase == target_name.to_s.downcase }
        return { error: t('osr_rpg.combatant_not_found', name: target_name) } unless c

        c['hp'] = [c['hp'].to_i + amount.to_i, c['hp_max'].to_i].min
        if c['char_id'].present? && !c['is_npc']
          char = Character[c['char_id']]
          Resources.adjust_hp(char, amount.to_i) if char
        end
        save_combatants(record, list)
        emit_scene(scene, t('osr_rpg.combat_heal', name: c['name'], amount: amount, hp: c['hp']))
        { combatant: c }
      end

      def self.reroll_initiative(scene, target_name)
        record = for_scene(scene)
        return { error: t('osr_rpg.combat_not_active') } unless record.active

        list = combatants(record).dup
        c = list.find { |x| x['name'].to_s.downcase == target_name.to_s.downcase }
        return { error: t('osr_rpg.combatant_not_found', name: target_name) } unless c

        roll = rand(1..20)
        if c['char_id'].present? && !c['is_npc']
          char = Character[c['char_id']]
          if char
            dex = char.osr_ability_scores['dex'] || char.osr_ability_scores[:dex]
            roll += Tables.ability_modifier(dex.to_i)
          end
        end
        c['initiative'] = roll
        save_combatants(record, list)
        { combatant: c, initiative: roll }
      end

      def self.summary(record)
        list = combatants(record).sort_by { |c| -c['initiative'].to_i }
        {
          active: record.active,
          combatants: list
        }
      end

      def self.emit_scene(scene, message)
        return unless scene&.room
        scene.room.emit_ooc message
        Scenes.add_to_scene(scene, message, Game.master.system_character, false, true)
      end
    end
  end
end
