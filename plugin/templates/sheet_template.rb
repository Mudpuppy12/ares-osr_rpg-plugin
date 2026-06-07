module AresMUSH
  module Rpg
    class SheetTemplate < ErbTemplateRenderer
      attr_accessor :char

      def initialize(char)
        @char = char
        @sheet = Chargen.build_sheet_display(char)
        super File.dirname(__FILE__) + '/sheet.erb'
      end

      def title
        t('rpg.sheet_title', name: char.name)
      end

      def sheet
        @sheet
      end
    end
  end
end
