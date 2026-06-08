module AresMUSH
  module OsrRpg
    class InstallCmd
      include CommandHandler

      def check_can_manage
        return t('dispatcher.not_allowed') unless Manage.can_manage_game?(enactor)
        nil
      end

      def handle
        InstallHooks.run.each do |line|
          client.emit_success line
        end
      end
    end
  end
end
