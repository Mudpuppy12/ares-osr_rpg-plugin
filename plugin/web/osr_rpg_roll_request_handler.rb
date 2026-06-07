module AresMUSH
  module OsrRpg
    class RollRequestHandler
      def handle(request)
        error = Website.check_login(request)
        return error if error

        char = request.enactor
        return { error: t('webportal.not_found') } unless char

        roll_count = Chargen.increment_ability_roll_count(char)

        if request.args['pool']
          pool = 6.times.map do |i|
            detail = Tables.roll_3d6_detail
            { id: i, dice: detail[:dice], total: detail[:total], assigned_to: nil }
          end
          return { pool: pool, ability_roll_count: roll_count }
        end

        abilities = request.args['abilities']
        abilities = Tables.abilities if abilities.nil? || abilities.empty?
        rolls = {}
        abilities.each do |ab|
          key = ab.to_s
          detail = Tables.roll_3d6_detail
          rolls[key] = { dice: detail[:dice], total: detail[:total] }
        end
        { rolls: rolls, ability_roll_count: roll_count }
      end
    end
  end
end
