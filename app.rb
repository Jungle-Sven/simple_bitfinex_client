require_relative "api.rb"
include API
require_relative "dataclasses.rb"
include Dataclasses

module App
  class BitfinexClient
    #an app to work with Bitfinex api
    #can submit orders
    #can recieve open orders from exchange
    def initialize(config_filename)
      @config_filename = config_filename
      @api = API::BitfinexREST.new(@config_filename)
    end

    def show_my_orders
      puts 'Market? Available markets are: BTCUSD, ETHUSD, etc'
      market = gets
      orders = @api.open_orders(symbol=market.strip)
      parsed_orders = @api.parse_open_orders(orders)
      for order in parsed_orders
        print_order order
      end
      if parsed_orders == []
        puts 'No open orders found for market ' + market
      end
    end

    def submit_order_user_input
      puts 'Market? Available markets are: BTCUSD, ETHUSD, etc'
      symbol = gets.strip.upcase()
      puts 'Amount?'
      amount = gets.strip
      puts 'Price?'
      price = gets.strip
      puts 'Side? Available side are BUY or SELL'
      side = gets.strip.upcase()
      if ['sell', 'Sell', 'SELL'].include? side.strip
        amount = -amount.to_f
      end
      puts 'Order type? Available types are: LIMIT, MARKET'
      order_type = 'EXCHANGE ' + gets.strip.upcase()
      status = 'NEW'
      order = Dataclasses::Order.new(symbol, amount.to_f, order_type, status, price.to_f)

      puts 'Plz confirm all data is correct.'
      print_order order
      puts 'y/n?'
      input_correct = gets.strip
      if ['y', 'Y', 'yes', 'Yes', 'YES', '1'].include? input_correct
        return order
      else
        puts 'Input was not confirmed, order will not be submitted.'
        return nil
      end
    end

    def submit_order
      order = submit_order_user_input
      if order
        response = @api.place_order(symbol=order.symbol, amount=order.amount.to_s, price=order.price.to_s, side=order.side, order_type=order.order_type)
        parsed_order = @api.parse_submitted_order(response)
        if parsed_order
          puts 'order submitted'
          print_order parsed_order
        end
      end
    end

    def print_order(order)
      puts 'printing order'
      puts order.side + ' ' + order.amount.abs.to_s + ' ' + order.symbol + ' @ ' + order.price.to_s + ' with ' +  order.order_type + ' order, status is' + ' ' +  order.status
    end

    def run
      puts 'GM! This is a simple ruby app to work with orders @ Bitfinex'
      puts 'enter 1 to show current open orders'
      puts 'enter 2 to submit new order'
      user_input = gets
      case user_input.to_i
      when 1
        puts 'list of orders'
        show_my_orders
      when 2
        puts 'creating a new order'
        submit_order
      else
        puts 'wrong input'
      end
    end
  end
end


if __FILE__ == $0
  app = App::BitfinexClient.new("cfg.yaml")
  app.run
end
