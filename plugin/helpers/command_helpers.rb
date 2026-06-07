module AresMUSH
  module OsrRpg
    module CommandHelpers
      def self.sheet_applied?(char)
        !char.osr_thac0.nil?
      end

      def self.can_set_other?(enactor)
        enactor && enactor.has_permission?('admin')
      end

      def self.parse_target_first_arg(args, enactor_name, allow_target: false)
        return [enactor_name, nil] if args.blank?

        if allow_target && args.include?('/')
          name, remainder = args.split('/', 2)
          return [name.strip, remainder]
        end

        [enactor_name, args]
      end
    end
  end
end
