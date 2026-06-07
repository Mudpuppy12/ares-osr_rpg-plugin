module AresMUSH
  module OsrRpg
    class SpellCmd
      include CommandHandler

      attr_accessor :name, :spell_args

      def parse_args
        allow = CommandHelpers.can_set_other?(enactor)
        self.name, remainder = CommandHelpers.parse_target_first_arg(cmd.args, enactor_name, allow_target: allow)
        self.spell_args = remainder ? remainder.strip : nil
      end

      def check_can_set
        return nil if enactor_name == self.name
        return nil if CommandHelpers.can_set_other?(enactor)
        return t('dispatcher.not_allowed')
      end

      def check_chargen_locked
        return nil if CommandHelpers.can_set_other?(enactor) && enactor_name != self.name
        AresMUSH::Chargen.check_chargen_locked(enactor) if enactor_name == self.name
      end

      def handle
        ClassTargetFinder.with_a_character(self.name, client, enactor) do |model|
          if self.spell_args.blank?
            emit_spell_info(model)
            return
          end

          spells = self.spell_args.split(/[,\/]/).map(&:strip).reject(&:blank?)
          return client.emit_failure(t('osr_rpg.spell_args_required')) if spells.empty?

          result = Chargen.set_spell_book(model, spells)
          if result.is_a?(Array) && result.any?
            client.emit_failure result.join('%r')
          elsif result.is_a?(String)
            client.emit_failure result
          else
            labels = (model.osr_spell_book['1'] || model.osr_spell_book[1] || []).join(', ')
            client.emit_success t('osr_rpg.spell_set', spells: labels)
          end
        end
      end

      def emit_spell_info(model)
        class_key = model.osr_class
        return client.emit_failure(t('osr_rpg.class_not_set')) if class_key.blank?

        casting = Tables.casting_type(class_key)
        case casting
        when 'arcane'
          names = Tables.arcane_l1_spell_names(class_key)
          client.emit "%xrArcane L1 spells (pick #{Tables.l1_spell_slot_count(class_key)}):%xn%r#{names.join(', ')}"
        when 'divine'
          tradition = Tables.spell_tradition(class_key)
          client.emit_success t('osr_rpg.spell_info_divine', tradition: tradition.to_s.titleize)
        when 'restricted'
          required = Tables.restricted_l1_spells(class_key)
          client.emit "%xrRestricted L1:%xn #{required.join(', ')}"
        else
          client.emit_success t('osr_rpg.spell_info_none')
        end
      end
    end
  end
end
