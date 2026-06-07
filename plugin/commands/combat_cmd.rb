module AresMUSH
  module OsrRpg
    class CombatCmd
      include CommandHandler

      attr_accessor :action, :target, :amount, :scene

      def parse_args
        parts = cmd.args.to_s.split(/\s+/, 2)
        self.action = parts[0].to_s.downcase
        rest = parts[1].to_s
        case self.action
        when 'damage', 'heal', 'init'
          if rest =~ /^(.+?)=(.+)$/
            self.target = $1.strip
            self.amount = $2.to_i
          else
            self.target = rest
          end
        else
          self.target = rest.presence
        end
      end

      def scene_for_enactor
        return nil unless enactor.room&.scene
        enactor.room.scene
      end

      def check_scene
        self.scene = scene_for_enactor
        return t('osr_rpg.combat_no_scene') unless self.scene
        nil
      end

      def check_can_manage
        return nil if %w[join init].include?(self.action)
        return nil if CommandHelpers.can_manage_osr_rpg?(enactor)
        return t('dispatcher.not_allowed')
      end

      def handle
        case self.action
        when 'start'
          Combat.start_combat(self.scene, enactor)
          client.emit_success t('osr_rpg.combat_started_local')
        when 'end'
          Combat.end_combat(self.scene, enactor)
          client.emit_success t('osr_rpg.combat_ended_local')
        when 'join'
          result = Combat.join_combat(self.scene, enactor)
          if result[:error]
            client.emit_failure result[:error]
          else
            client.emit_success t('osr_rpg.combat_joined', initiative: result[:initiative])
          end
        when 'init'
          result = Combat.reroll_initiative(self.scene, self.target)
          if result[:error]
            client.emit_failure result[:error]
          else
            client.emit_success t('osr_rpg.combat_init', name: self.target, initiative: result[:initiative])
          end
        when 'damage'
          result = Combat.apply_damage(self.scene, self.target, self.amount)
          if result[:error]
            client.emit_failure(result[:error])
          else
            client.emit_success t('osr_rpg.combat_damage', name: self.target, amount: self.amount, hp: result[:combatant]['hp'])
          end
        when 'heal'
          result = Combat.apply_heal(self.scene, self.target, self.amount)
          if result[:error]
            client.emit_failure(result[:error])
          else
            client.emit_success t('osr_rpg.combat_heal', name: self.target, amount: self.amount, hp: result[:combatant]['hp'])
          end
        when 'summary', ''
          summary = Combat.summary(Combat.for_scene(self.scene))
          lines = summary[:combatants].map do |c|
            t('osr_rpg.combat_line', name: c['name'], init: c['initiative'], hp: c['hp'], hp_max: c['hp_max'], ac: c['ac'])
          end
          header = summary[:active] ? t('osr_rpg.combat_active') : t('osr_rpg.combat_inactive')
          client.emit_success "#{header}%r#{lines.join('%r')}"
        else
          client.emit_failure t('osr_rpg.invalid_combat_action', action: self.action)
        end
      end
    end
  end
end
