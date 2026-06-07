$:.unshift File.dirname(__FILE__)

module AresMUSH
  module Rpg
    def self.plugin_dir
      File.dirname(__FILE__)
    end

    def self.shortcuts
      Global.read_config('rpg', 'shortcuts')
    end

    def self.get_cmd_handler(client, cmd, enactor)
      case cmd.root
      when 'sheet'
        return SheetCmd
      end
      nil
    end

    def self.get_event_handler(event_name)
      nil
    end

    def self.get_web_request_handler(request)
      case request.cmd
      when 'rpgChargenInfo'
        return ChargenInfoRequestHandler
      end
      nil
    end

    def self.save_char(char, chargen_data)
      Rpg::Chargen.save_char(char, chargen_data['rpg'] || {})
    end

    def self.get_sheet_for_web_editing(char, enactor)
      Rpg::Chargen.sheet_for_web_editing(char, enactor)
    end

    def self.get_sheet_for_web_viewing(char, enactor)
      Rpg::Chargen.sheet_for_web_viewing(char, enactor)
    end

    def self.app_review(char)
      Rpg::Chargen.app_review(char)
    end
  end
end
