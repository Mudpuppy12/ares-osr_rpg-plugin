module AresMUSH
  module OsrRpg
    class InstallCheckCmd
      include CommandHandler

      def check_can_manage
        return t('dispatcher.not_allowed') unless Manage.can_manage_game?(enactor)
        nil
      end

      def handle
        result = InstallHooks.check
        if result[:issues].empty? && result[:warnings].empty?
          client.emit_success t('osr_rpg.install_check_ok')
          return
        end

        result[:issues].each do |issue|
          client.emit_failure issue
        end
        result[:warnings].each do |warning|
          client.emit_success "#{t('osr_rpg.install_check_warning')}: #{warning}"
        end

        if result[:issues].any?
          client.emit_success t('osr_rpg.install_check_fix', cmd: 'osr_rpg/install')
        end
      end
    end
  end
end
