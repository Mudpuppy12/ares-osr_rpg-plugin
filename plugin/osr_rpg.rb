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
      when 'osrRpgRollAbilities'
        return RollRequestHandler
      when 'osrRpgSceneSheet'
        return SceneSheetRequestHandler
      when 'osrRpgSceneRoll'
        return SceneRollRequestHandler
      when 'osrRpgLevelUp'
        return LevelUpRequestHandler
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

  # Ares plugin loader matches folder name `osr_rpg` to constant Osr_rpg (case-insensitive).
  Osr_rpg = OsrRpg unless const_defined?(:Osr_rpg)
end
