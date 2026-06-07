module AresMUSH
  module OsrRpg
    class ClassesCmd
      include CommandHandler

      attr_accessor :group

      def parse_args
        self.group = cmd.args ? cmd.args.strip.downcase : nil
      end

      def handle
        groups = Tables.grouped_classes_for_web
        if self.group.present?
          groups = groups.select { |g| g[:group].to_s.downcase == self.group }
          if groups.empty?
            client.emit_failure t('osr_rpg.invalid_class_group', group: self.group)
            return
          end
        end

        lines = [t('osr_rpg.classes_header')]
        groups.each do |g|
          lines << "%xb#{g[:label]}:%xn"
          g[:classes].each do |cls|
            line = "  #{cls[:key]} - #{cls[:name]}"
            line += " (#{cls[:race]})" if cls[:race]
            lines << line
          end
        end
        client.emit lines.join('%r')
      end
    end
  end
end
