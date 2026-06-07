module AresMUSH
  module OsrRpg
    module Rolls
      SAVE_CATEGORIES = %w[death wands paralysis breath spells].freeze

      def self.scene_sheet(char)
        return nil unless Leveling.sheet_ready?(char)

        sheet = Chargen.build_sheet_display(char)
        {
          class_name: sheet[:class_name],
          class_key: sheet[:class_key],
          level: sheet[:level],
          hp: sheet[:hp],
          hp_max: sheet[:hp_max],
          thac0: sheet[:thac0],
          saves: sheet[:saves],
          thief_skills: sheet[:thief_skills],
          abilities: sheet[:abilities],
          can_level_up: sheet[:can_level_up],
          xp: sheet[:xp],
          xp_to_next_level: sheet[:xp_to_next_level],
          expertise_unspent: sheet[:expertise_unspent]
        }
      end

      def self.thief_skill_chance(char, skill_key)
        skills = char.osr_thief_skills || {}
        key = Tables.normalize_key(skill_key)
        val = skills[key] || skills[key.to_sym]
        return nil if val.nil?

        base = Tables.base_thief_chance
        if CommandHelpers.sheet_applied?(char)
          val.to_i
        else
          base + val.to_i
        end
      end

      def self.roll_attack(char)
        roll = rand(1..20)
        thac0 = char.osr_thac0
        {
          roll: roll,
          thac0: thac0,
          message: t('osr_rpg.scene_roll_attack', name: char.name, roll: roll, thac0: thac0)
        }
      end

      def self.roll_save(char, category)
        cat = category.to_s.downcase
        return { error: t('osr_rpg.invalid_save_category', category: category) } unless SAVE_CATEGORIES.include?(cat)

        saves = char.osr_saving_throws || {}
        target = saves[cat] || saves[cat.to_sym]
        return { error: t('osr_rpg.no_save_value', category: cat) } if target.nil?

        roll = rand(1..20)
        success = roll >= target.to_i
        {
          roll: roll,
          target: target.to_i,
          category: cat,
          success: success,
          message: t('osr_rpg.scene_roll_save',
                     name: char.name,
                     category: cat.upcase,
                     roll: roll,
                     target: target,
                     result: success ? t('osr_rpg.roll_success') : t('osr_rpg.roll_failure'))
        }
      end

      def self.roll_thief_skill(char, skill_key)
        key = Tables.normalize_key(skill_key)
        chance = thief_skill_chance(char, key)
        return { error: t('osr_rpg.invalid_thief_skill', skill: skill_key) } if chance.nil?

        roll = rand(1..6)
        success = roll <= chance
        label = key.titleize.gsub('In ', 'in ')
        {
          roll: roll,
          chance: chance,
          skill: key,
          success: success,
          message: t('osr_rpg.scene_roll_skill',
                     name: char.name,
                     skill: label,
                     roll: roll,
                     chance: chance,
                     result: success ? t('osr_rpg.roll_success') : t('osr_rpg.roll_failure'))
        }
      end

      def self.roll_ability_check(char, ability, target = nil)
        ab = ability.to_s.downcase
        return { error: t('osr_rpg.invalid_ability', ability: ability) } unless Tables.abilities.include?(ab)

        scores = char.osr_ability_scores || {}
        score = scores[ab] || scores[ab.to_sym]
        mod = Tables.ability_modifier(score.to_i)
        roll = rand(1..20)
        total = roll + mod
        msg_key = target ? 'osr_rpg.scene_roll_ability_vs' : 'osr_rpg.scene_roll_ability'
        {
          roll: roll,
          modifier: mod,
          total: total,
          ability: ab,
          target: target,
          message: t(msg_key,
                     name: char.name,
                     ability: ab.upcase,
                     roll: roll,
                     mod: mod >= 0 ? "+#{mod}" : mod.to_s,
                     total: total,
                     target: target)
        }
      end

      def self.roll_generic(name, dice_str)
        args = ArgParser.parse(/(?<num>[\d]*)[dD](?<sides>[\d]+$)/, dice_str)
        num = (args.num || '0').to_i
        sides = (args.sides || '0').to_i
        message = Utils.roll_dice(name, num, sides)
        return { error: t('dice.invalid_dice_string') } unless message

        { message: message }
      end

      def self.emit_to_scene(scene, message)
        raise 'Scene has no room.' unless scene.room

        scene.room.emit_ooc message
        Scenes.add_to_scene(scene, message, Game.master.system_character, false, true)
      end

      def self.validate_scene_request(request, scene)
        error = Website.check_login(request)
        return error if error

        return { error: t('webportal.not_found') } unless scene
        return { error: t('scenes.access_not_allowed') } unless Scenes.can_read_scene?(request.enactor, scene)
        return { error: t('scenes.scene_already_completed') } if scene.completed

        nil
      end

      def self.resolve_sender(request)
        sender_name = request.args['sender']
        enactor = request.enactor
        sender = sender_name.present? ? Character.named(sender_name) : enactor
        return { error: t('webportal.not_found') } unless sender
        return { error: t('dispatcher.not_allowed') } unless AresCentral.is_alt?(sender, enactor)

        { sender: sender }
      end
    end
  end
end
