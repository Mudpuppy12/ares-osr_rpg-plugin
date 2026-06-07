module AresMUSH
  module OsrRpg
    class SpellDetailRequestHandler
      def handle(request)
        tradition = request.args[:tradition] || request.args['tradition']
        level = request.args[:level] || request.args['level']
        name = request.args[:name] || request.args['name']
        ReferenceData.spell_detail_for_web(tradition, level, name)
      end
    end
  end
end
