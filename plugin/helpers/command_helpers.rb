module AresMUSH
  module OsrRpg
    module CommandHelpers
      def self.sheet_applied?(char)
        !char.osr_thac0.nil?
      end

      def self.can_set_other?(enactor)
        enactor && enactor.has_permission?('admin')
      end

      def self.can_manage_osr_rpg?(actor)
        actor && (actor.has_permission?('admin') || actor.has_permission?('manage_osr_rpg') || actor.has_permission?('manage_osr_rpg_xp'))
      end

      def self.default_ac
        Global.read_config('osr_rpg', 'default_ac') || 9
      end

      def self.parse_target_first_arg(args, enactor_name, allow_target: false)
        return [enactor_name, nil] if args.blank?

        if allow_target && args.include?('/')
          name, remainder = args.split('/', 2)
          return [name.strip, remainder]
        end

        [enactor_name, args]
      end

      def self.parse_target_and_options(args, enactor_name, allow_target: false)
        name, remainder = parse_target_first_arg(args, enactor_name, allow_target: allow_target)
        options = {}
        rest = remainder.to_s.strip
        if rest.present?
          rest.split(/\s+/).each do |part|
            if part =~ /^ac=(.+)$/i
              options[:ac] = $1.to_i
            elsif part =~ /^vs=(.+)$/i
              options[:target] = $1.to_i
            elsif part =~ /^hd=(.+)$/i
              options[:hd] = $1.to_i
            end
          end
          remainder = rest.gsub(/\b(ac|vs|hd)=\S+/i, '').strip
          remainder = nil if remainder.blank?
        end
        [name, remainder, options]
      end

      def self.check_sheet_ready(char)
        return t('osr_rpg.no_sheet_for_levelup') unless Leveling.sheet_ready?(char)
        nil
      end
    end

    module PlayCmdSupport
      def self.included(base)
        base.send(:attr_accessor, :name, :remainder, :options)
      end

      def parse_play_target(allow_other: false)
        allow = allow_other && CommandHelpers.can_set_other?(enactor)
        self.name, self.remainder, self.options = CommandHelpers.parse_target_and_options(
          cmd.args, enactor_name, allow_target: allow
        )
      end

      def with_play_char
        ClassTargetFinder.with_a_character(self.name, client, enactor) do |model|
          error = CommandHelpers.check_sheet_ready(model)
          if error
            client.emit_failure error
            return
          end
          yield model
        end
      end
    end
  end
end
