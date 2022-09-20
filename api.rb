require "yaml"
#gem install openssl
require "openssl"
require 'json'
#gem install faraday
require 'faraday'
require_relative "dataclasses.rb"
include Dataclasses

module API
  class APIConfig

    def initialize(filename)
      @filename = filename
    end

    def write_cfg(api_key, api_secret)
      File.write(@filename, [api_key, api_secret].to_yaml)
    end

    def initial_setup
      puts 'This is initial setup.'
      puts 'Enter API key'
      api_key = gets.strip
      puts 'Enter API secret'
      api_secret = gets.strip
      write_cfg(api_key, api_secret)
      puts 'Config file updated.'
    end

    def read_config
      api_key, api_secret = YAML.load_file(@filename)
    end
  end

  class BitfinexREST
    def initialize(config_filename)
      config = API::APIConfig.new(config_filename)
      @api_key = config.read_config[0]
      @api_secret = config.read_config[1]
      @api_url = 'https://api.bitfinex.com'
      @nonce = ''

    end

    def get_nonce
      @nonce = (Time.now.utc.to_f * 1000000).floor.to_s
    end

    def add_headers(path, body)
      get_nonce
      signature = '/api' + path + @nonce.to_s + body.to_s
      signature = sign(signature)
      return {"bfx-nonce" => @nonce,
              "bfx-apikey" => @api_key,
              "bfx-signature" => signature,
              "Content-Type" => 'application/json'}
    end

    def sign(signature)
      OpenSSL::HMAC.hexdigest('sha384', @api_secret, signature)
    end

    def api_call(method, param={})
      full_address = @api_url + method
      conn = Faraday.new(url: full_address)
      headers = add_headers(path=method, body=param.to_json)
      response = conn.post(full_address, param.to_json, headers)
      return response
    end

    def open_orders(symbol)
      url = '/v2/auth/r/orders/t' + symbol.upcase()
      response = api_call(url)
      parsed_json = JSON.parse(response.body)
      return parsed_json
    end

    def place_order(symbol, amount, price, side, order_type)
      symbol = 't' + symbol.upcase() #format is tBTCUSD
      url = '/v2/auth/w/order/submit'
      param = {
              'symbol'=> symbol,
              'amount'=> amount,
              'price'=> price,
              'side'=> side,
              'type'=> order_type
          }
      response = api_call(url, param=param)
      parsed_json = JSON.parse(response.body)
      return parsed_json
    end

    def parse_open_orders(list_of_orders)
      result = []
      list_of_orders.each do |o|
        order = Dataclasses::Order.new(symbol=o[3], amount=o[6], order_type=o[8], status=o[13], price=o[16])
        result.append(order)
      end
      return result
    end

    def parse_submitted_order(data)
      if data[0] == 'error'
        error_code = data[1]
        error_message = data[2]
        puts('error_code: ' + error_code.to_s + ' ' + 'error_message: ' + error_message)
        return nil
      else
        order = Dataclasses::Order.new(symbol=data[4][0][3], amount=data[4][0][6], order_type=data[4][0][8], status=data[4][0][13], price=data[4][0][16])
        return order
      end
    end
  end
end
