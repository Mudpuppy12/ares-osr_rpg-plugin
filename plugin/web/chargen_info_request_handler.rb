module AresMUSH
  module OsrRpg
    class ChargenInfoRequestHandler
      def handle(_request)
        {
          class_groups: Tables.grouped_classes_for_web,
          alignments: Tables.alignments,
          abilities: Tables.abilities,
          thief_skill_defs: Chargen.thief_skill_defs,
          l1_expertise_points: Tables.l1_expertise_points,
          thief_skills_blurb: 'Roll d6; succeed on ≤ chance. Base 1-in-6; add expertise at chargen (Thief: 4 points).',
          ability_modifiers: Global.read_config('osr', 'ability_modifiers') || {},
          require_server_rolls: Global.read_config('osr_rpg', 'require_server_rolls') != false
        }
      end
    end
  end
end
