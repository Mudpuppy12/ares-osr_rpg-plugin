module AresMUSH
  module OsrRpg
    class SpellActionRequestHandler
      def handle(request)
        error = Website.check_login(request)
        return { error: error } if error

        enactor = request.enactor
        return { error: t('osr_rpg.no_sheet_for_levelup') } unless Leveling.sheet_ready?(enactor)

        action = request.args['action'].to_s
        spell = request.args['spell']
        result = case action
                 when 'prepare'
                   Spellcasting.prepare_spell(enactor, spell)
                 when 'cast'
                   Spellcasting.cast_spell(enactor, spell)
                 when 'rest'
                   Spellcasting.rest_spells(enactor)
                   { message: t('osr_rpg.rest_complete', name: enactor.name) }
                 else
                   { error: t('osr_rpg.invalid_spell_action', action: action) }
                 end
        return result if result[:error]

        {
          sheet: Chargen.build_sheet_display(enactor),
          message: result[:message] || t('osr_rpg.spell_prepared', spell: result[:spell], level: result[:level])
        }
      end
    end
  end
end
