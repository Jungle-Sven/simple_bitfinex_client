module Dataclasses

  class Order
    attr_accessor :symbol, :amount, :order_type, :status, :price, :side

    def find_order_side(amount)
      side = ''
      if amount > 0
        side = 'BUY'
      end
      if amount < 0
        side = 'SELL'
      end
      return side
    end

    def initialize(symbol, amount, order_type, status, price)
      @symbol = symbol
      @amount = amount
      @order_type = order_type
      @status = status
      @price = price
      @side = find_order_side(amount)
    end

  end

end
