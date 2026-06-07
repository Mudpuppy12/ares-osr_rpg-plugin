module AresMUSH
  module OsrRpg
    class ShopStateRequestHandler
      def handle(request)
        error = Website.check_login(request)
        return { error: error } if error

        ShopHelper.state_for_web(request.enactor)
      end
    end
  end
end
