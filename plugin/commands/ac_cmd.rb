module AresMUSH
  module OsrRpg
    class AcCmd
      include CommandHandler
      include PlayCmdSupport

      def parse_args
        parse_play_target(allow_other: true)
      end

      def check_can_set
        return nil if enactor_name == self.name
        return nil if CommandHelpers.can_manage_osr_rpg?(enactor)
        return t('dispatcher.not_allowed')
      end

      def handle
        with_play_char do |model|
          if self.remainder.present?
            unless enactor_name == model.name || CommandHelpers.can_manage_osr_rpg?(enactor)
              client.emit_failure t('dispatcher.not_allowed')
              return
            end
            ac = Resources.set_ac(model, self.remainder.to_i)
            client.emit_success t('osr_rpg.ac_set', name: model.name, ac: ac)
          else
            client.emit_success t('osr_rpg.ac_status', name: model.name, ac: Resources.current_ac(model))
          end
        end
      end
    end
  end
end
