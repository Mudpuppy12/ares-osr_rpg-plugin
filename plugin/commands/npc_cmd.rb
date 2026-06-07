module AresMUSH
  module OsrRpg
    class NpcCmd
      include CommandHandler

      attr_accessor :template_key, :label, :scene

      def parse_args
        parts = cmd.args.to_s.split(/\s+/, 2)
        self.template_key = parts[0].to_s.downcase
        self.label = parts[1]
      end

      def required_args
        [self.template_key]
      end

      def check_can_manage
        return nil if CommandHelpers.can_manage_osr_rpg?(enactor)
        return t('dispatcher.not_allowed')
      end

      def handle
        self.scene = enactor.room&.scene
        tpl = StaffTools.npc_template(self.template_key)
        unless tpl
          client.emit_failure t('osr_rpg.invalid_npc_template', template: self.template_key)
          return
        end

        unless self.scene
          lines = [
            tpl['name'] || self.template_key.titleize,
            "HD #{tpl['hd']}  AC #{tpl['ac']}  THAC0 #{tpl['thac0']}  HP #{tpl['hp']}  XP #{tpl['xp']}"
          ]
          client.emit_success lines.join('%r')
          return
        end

        record = Combat.for_scene(self.scene)
        unless record.active
          Combat.start_combat(self.scene, enactor)
        end
        result = Combat.add_npc(self.scene, self.template_key, self.label)
        if result[:error]
          client.emit_failure result[:error]
        else
          c = result[:combatant]
          client.emit_success t('osr_rpg.npc_added', name: c['name'], ac: c['ac'], hp: c['hp'])
        end
      end
    end
  end
end
