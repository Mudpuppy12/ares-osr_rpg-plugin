module AresMUSH
  module OsrRpg
    module StaffTools
      def self.roll_treasure(table_key)
        tables = Global.read_config('osr', 'treasure_tables') || {}
        table = tables[table_key.to_s] || tables[table_key.to_sym]
        return { error: t('osr_rpg.invalid_treasure_table', table: table_key) } unless table

        dice = table['dice'].to_s
        match = dice.match(/(\d+)d(\d+)/i)
        return { error: t('osr_rpg.invalid_treasure_table', table: table_key) } unless match

        num = match[1].to_i
        sides = match[2].to_i
        total = num.times.sum { rand(1..sides) }
        gp = total * table['multiplier'].to_i
        {
          table: table['name'] || table_key,
          roll: total,
          gp: gp,
          message: t('osr_rpg.treasure_rolled', table: table['name'] || table_key, gp: gp, roll: total)
        }
      end

      def self.monster_xp(hd)
        table = Global.read_config('osr', 'monster_xp', 'by_hd') || {}
        (table[hd.to_s] || table[hd.to_i.to_s] || table['default'] || 0).to_i
      end

      def self.npc_template(key)
        templates = Global.read_config('osr', 'npc_templates') || {}
        templates[key.to_s] || templates[key.to_sym]
      end
    end
  end
end
