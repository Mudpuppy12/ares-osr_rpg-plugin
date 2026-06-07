$:.unshift File.dirname(__FILE__)

module AresMUSH
  module OsrRpg
    def self.plugin_dir
      File.dirname(__FILE__)
    end

    def self.shortcuts
      Global.read_config('osr_rpg', 'shortcuts')
    end

    def self.get_cmd_handler(client, cmd, enactor)
      case cmd.root
      when 'sheet'
        return SheetCmd
      when 'osr_rpg'
        case cmd.switch
        when 'classes'
          return ClassesCmd
        when 'class'
          return ClassCmd
        when 'alignment'
          return AlignmentCmd
        when 'roll'
          return RollCmd
        when 'ability'
          return AbilityCmd
        when 'thief'
          return ThiefCmd
        when 'skills'
          return SkillsCmd
        when 'spell'
          return SpellCmd
        when 'finish'
          return FinishCmd
        when 'reset'
          return ResetCmd
        when 'levelup'
          return LevelupCmd
        when 'attack'
          return AttackCmd
        when 'save'
          return SaveCmd
        when 'skill'
          return SkillRollCmd
        when 'check'
          return CheckCmd
        when 'dice'
          return DiceCmd
        when 'hp'
          return HpCmd
        when 'hp/set'
          return HpCmd
        when 'ac'
          return AcCmd
        when 'prepare'
          return PrepareCmd
        when 'cast'
          return CastCmd
        when 'learn'
          return LearnCmd
        when 'rest'
          return RestCmd
        when 'combat'
          return CombatCmd
        when 'backstab'
          return BackstabCmd
        when 'turn'
          return TurnCmd
        when 'track'
          return TrackCmd
        when 'explore'
          return ExploreCmd
        when 'equip', 'unequip'
          return EquipCmd
        when 'gear', 'inventory'
          return GearCmd
        when 'buy'
          return BuyCmd
        when 'sell'
          return SellCmd
        when 'treasure'
          return TreasureCmd
        when 'npc'
          return NpcCmd
        when 'xp'
          return XpCmd if cmd.args.blank?
          return XpAwardCmd
        when 'xp/remove'
          return XpAwardCmd
        end
      end
      nil
    end

    def self.get_event_handler(event_name)
      nil
    end

    def self.get_web_request_handler(request)
      case request.cmd
      when 'osrRpgChargenInfo'
        return ChargenInfoRequestHandler
      when 'osrRpgEnsureStartingGold'
        return EnsureStartingGoldRequestHandler
      when 'osrRpgResetShop'
        return ResetShopRequestHandler
      when 'osrRpgRollAbilities'
        return RollRequestHandler
      when 'osrRpgSceneSheet'
        return SceneSheetRequestHandler
      when 'osrRpgSceneRoll'
        return SceneRollRequestHandler
      when 'osrRpgSceneCombat'
        return SceneCombatRequestHandler
      when 'osrRpgLevelUp'
        return LevelUpRequestHandler
      when 'osrRpgAdjustHp'
        return AdjustHpRequestHandler
      when 'osrRpgSpendExpertise'
        return SpendExpertiseRequestHandler
      when 'osrRpgSpellAction'
        return SpellActionRequestHandler
      when 'osrRpgSpells'
        return SpellsListRequestHandler
      when 'osrRpgSpellDetail'
        return SpellDetailRequestHandler
      when 'osrRpgEquipment'
        return EquipmentListRequestHandler
      when 'osrRpgEquip'
        return EquipRequestHandler
      end
      nil
    end

    def self.save_char(char, chargen_data)
      OsrRpg::Chargen.save_char(char, chargen_data['osr_rpg'] || {})
    end

    def self.get_sheet_for_web_editing(char, enactor)
      OsrRpg::Chargen.sheet_for_web_editing(char, enactor)
    end

    def self.get_sheet_for_web_viewing(char, enactor)
      OsrRpg::Chargen.sheet_for_web_viewing(char, enactor)
    end

    def self.app_review(char)
      OsrRpg::Chargen.app_review(char)
    end
  end

  Osr_rpg = OsrRpg unless const_defined?(:Osr_rpg)
end
