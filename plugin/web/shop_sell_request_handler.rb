module AresMUSH
  module OsrRpg
    class ShopSellRequestHandler
      def handle(request)
        error = Website.check_login(request)
        return { error: error } if error

        enactor = request.enactor
        item = request.args['item'].to_s
        qty = [request.args['qty'].to_i, 1].max
        return { error: t('osr_rpg.invalid_equipment', item: item) } if item.blank?

        result = ShopHelper.sell_item(enactor, item, qty)
        return result if result[:error]

        result[:message] = t('osr_rpg.shop_sell_success',
                             item: result[:item],
                             qty: result[:qty],
                             credit: result[:credit],
                             gold: result[:gold])
        ShopHelper.response_after_transaction(enactor, result)
      end
    end
  end
end
