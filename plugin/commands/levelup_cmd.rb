module AresMUSH
  module OsrRpg
    class LevelupCmd
      include CommandHandler

      attr_accessor :name, :bypass_xp

      def parse_args
        if cmd.args.blank?
          self.name = enactor_name
          self.bypass_xp = false
        else
          self.name = titlecase_arg(cmd.args)
          self.bypass_xp = Leveling.can_manage_xp?(enactor) && enactor_name != self.name
        end
      end

      def check_can_level
        return nil if enactor_name == self.name
        return nil if Leveling.can_manage_xp?(enactor)
        return t('dispatcher.not_allowed')
      end

      def check_approved
        return nil if enactor_name != self.name
        return nil if enactor.is_approved?
        return t('osr_rpg.must_be_approved_to_level')
      end

      def handle
        ClassTargetFinder.with_a_character(self.name, client, enactor) do |model|
          result = Leveling.apply_level_up(model, bypass_xp: self.bypass_xp)
          if result[:error]
            client.emit_failure result[:error]
            return
          end

          Global.logger.info "#{model.name} leveled to #{result[:level]} (+#{result[:hp_added]} HP) by #{enactor_name}"
          client.emit_success t('osr_rpg.levelup_success',
                                name: model.name,
                                level: result[:level],
                                hp_added: result[:hp_added],
                                hp: result[:hp],
                                hp_max: result[:hp_max])
          template = SheetTemplate.new(model)
          client.emit template.render
        end
      end
    end
  end
end
