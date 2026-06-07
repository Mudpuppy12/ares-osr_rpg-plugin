module AresMUSH
  module OsrRpg
    class XpCmd
      include CommandHandler

      def handle
        status = Leveling.xp_status(enactor)
        lines = [
          t('osr_rpg.xp_status', level: status[:level], xp: status[:xp])
        ]
        bonus = enactor.osr_xp_bonus || 0
        if bonus != 0
          lines << t('osr_rpg.xp_prime_bonus_note', bonus_percent: bonus)
        end
        if status[:next_level]
          lines << t('osr_rpg.xp_next_level', level: status[:next_level], xp: status[:xp_to_next_level])
          if status[:can_level_up]
            lines << t('osr_rpg.xp_ready_to_level')
          end
        else
          lines << t('osr_rpg.at_max_level')
        end
        client.emit lines.join('%r')
      end
    end
  end
end
