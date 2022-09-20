#simple tests
require_relative "dataclasses.rb"
include Dataclasses
require_relative "api.rb"
include API
require_relative "app.rb"
include App

CONFIG_FILENAME = "cfg.yaml"

class TestOrder
  def test_order_class
    puts 'test_order_class'
    symbol = 'BTCUSD'
    amount = -0.035
    order_type = 'LIMIT'
    status = 'NEW'
    price = 18888
    order = Dataclasses::Order.new(symbol, amount, order_type, status, price)
    puts order.symbol + order.amount.to_s + order.order_type + order.status + order.price.to_s

  end

  def test_find_order_side_func
    puts 'test_find_order_side'
    symbol = 'BTCUSD'
    amount = -0.035
    order_type = 'LIMIT'
    status = 'NEW'
    price = 18888
    order = Dataclasses::Order.new(symbol, amount, order_type, status, price)
    puts 'order amount is ' + order.amount.to_s + ' order side is ' + order.side
    order2 = Dataclasses::Order.new(symbol, -amount, order_type, status, price)
    puts 'order2 amount is ' + order2.amount.to_s + ' order side is ' + order2.side
  end

  def run_all_tests
    test_order_class
    test_find_order_side_func
  end
end

class TestAPI
  def initialize(config_filename)
    @config_filename = config_filename
  end

  def test_config
    apicfg = API::APIConfig.new(@config_filename)
    api_keys = apicfg.read_config
    puts 'API key: ' + api_keys[0]
    puts 'API secret: ' + api_keys[1]
  end

  def test_nonce
    bfx_api = API::BitfinexREST.new(@config_filename)
    nonce = bfx_api.get_nonce
    puts 'nonce is ' + nonce.to_s
  end

  def test_headers
    bfx_api = API::BitfinexREST.new(@config_filename)
    path = '/v2/auth/r/orders/tETCUSD'
    body = {}
    headers = bfx_api.add_headers(path, body)
    puts headers
  end

  def test_open_orders
    bfx_api = API::BitfinexREST.new(@config_filename)
    resp = bfx_api.open_orders('ETCUSD')
    puts resp
  end

  def test_place_order
    bfx_api = API::BitfinexREST.new(@config_filename)
    resp = bfx_api.place_order('ETCUSD', '0.1', '27', 'BUY', 'EXCHANGE LIMIT')
    puts resp
  end

  def test_parse_open_orders
    bfx_api = API::BitfinexREST.new(@config_filename)
    resp = bfx_api.open_orders('ETCUSD')
    parsed_orders = bfx_api.parse_open_orders(resp)
    for order in parsed_orders
      puts order
    end
  end

  def test_parse_submitted_order
    bfx_api = API::BitfinexREST.new(@config_filename)
    resp = bfx_api.place_order('ETCUSD', '5.1', '27', 'BUY', 'EXCHANGE LIMIT')
    parsed_order = bfx_api.parse_submitted_order(resp)
    puts parsed_order
  end

  def test_initial_setup
    apicfg = API::APIConfig.new(@config_filename)
    apicfg.initial_setup
  end

  def run_all_tests
    test_config
    test_nonce
    test_headers
    test_open_orders
    test_place_order
    test_parse_open_orders
    test_parse_submitted_order
  end

end

class TestApp
  def initialize(config_filename)
    @config_filename = config_filename
  end

  def test_run
    app = App::BitfinexClient.new(@config_filename)
    app.run
  end

  def test_show_open_orders
    app = App::BitfinexClient.new(@config_filename)
    app.show_my_orders
  end

  def test_submit_order
    app = App::BitfinexClient.new(@config_filename)
    app.submit_order
  end

  def run_all_tests
    test_run
    #test_show_open_orders
    #test_submit_order
  end
end

test_order = TestOrder.new
#test_order.run_all_tests

test_api = TestAPI.new(CONFIG_FILENAME)
#test_api.run_all_tests
test_api.test_initial_setup

test_app = TestApp.new(CONFIG_FILENAME)
#test_app.run_all_tests
