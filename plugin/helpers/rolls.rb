module AresMUSH
  module OsrRpg
    module Rolls
      SAVE_CATEGORIES = %w[death wands paralysis breath spells].freeze
      PLAY_ROLL_TYPES = %w[attack save skill ability generic exploration backstab turn track].freeze

      def self.scene_sheet(char)
        return nil unless Leveling.sheet_ready?(char)

        sheet = Chargen.build_sheet_display(char)
        sheet.merge(
          char_name: char.name,
          name: char.fullname.presence || char.name,
          icon: Website.icon_for_char(char)
        )
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

      def self.roll_attack(char, target_ac: nil)
        roll = rand(1..20)
        thac0 = char.osr_thac0
        hit = nil
        needed = nil
        if target_ac
          needed = CommandHelpers.attack_needed_roll(thac0, target_ac)
          hit = roll >= needed
        end
        msg_key = target_ac ? 'osr_rpg.scene_roll_attack_vs' : 'osr_rpg.scene_roll_attack'
        {
          roll: roll,
          thac0: thac0,
          target_ac: target_ac,
          needed: needed,
          hit: hit,
          message: t(msg_key,
                     name: char.name,
                     roll: roll,
                     thac0: thac0,
                     ac: target_ac,
                     needed: needed,
                     result: hit ? t('osr_rpg.roll_hit') : t('osr_rpg.roll_miss'))
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
        success = target ? total >= target.to_i : nil
        msg_key = target ? 'osr_rpg.scene_roll_ability_vs' : 'osr_rpg.scene_roll_ability'
        result_text = if target
                        success ? t('osr_rpg.roll_success') : t('osr_rpg.roll_failure')
                      else
                        ''
                      end
        {
          roll: roll,
          modifier: mod,
          total: total,
          ability: ab,
          target: target,
          success: success,
          message: t(msg_key,
                     name: char.name,
                     ability: ab.upcase,
                     roll: roll,
                     mod: mod >= 0 ? "+#{mod}" : mod.to_s,
                     total: total,
                     target: target,
                     result: result_text)
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

      def self.perform_roll(char, roll_type, options = {})
        case roll_type.to_s
        when 'attack'
          roll_attack(char, target_ac: options[:ac] || options['ac'])
        when 'save'
          roll_save(char, options[:category] || options['save_category'])
        when 'skill'
          roll_thief_skill(char, options[:skill])
        when 'ability', 'check'
          roll_ability_check(char, options[:ability], options[:target])
        when 'generic', 'dice'
          roll_generic(char.name, options[:dice_string] || options[:dice])
        when 'exploration'
          ClassFeatures.roll_exploration(char, options[:skill] || options[:exploration_skill])
        when 'backstab'
          ClassFeatures.roll_backstab(char, options[:ac] || options['ac'])
        when 'turn'
          ClassFeatures.roll_turn(char, options[:hd] || options['hd'] || 1)
        when 'track'
          ClassFeatures.roll_track(char, options[:target])
        else
          { error: t('osr_rpg.invalid_roll_type', type: roll_type) }
        end
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
