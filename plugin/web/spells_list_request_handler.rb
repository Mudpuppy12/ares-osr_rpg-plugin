module AresMUSH
  module OsrRpg
    class SpellsListRequestHandler
      def handle(request)
        tradition = request.args[:tradition] || request.args['tradition']
        ReferenceData.spells_for_web(tradition)
      end
    end
  end
end
