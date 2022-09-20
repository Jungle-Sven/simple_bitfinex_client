
import time
import requests
import json
import hmac
import hashlib

'''
нет error codes
не все публично доступные имплементации работают (скорее половина)
нет тестового сервера, нужно делать деп на реальный акк
нет order side (buy, sell), вместо этого отрицательное значение для продажи
'''

class Order:
    #data class
    def __init__(self, symbol, amount, order_type, status, price):
        self.symbol = symbol
        self.amount = amount
        self.type = order_type
        self.status = status
        self.price = price
        self.side = self.find_order_side(amount)

    def find_order_side(self, amount) -> str:
        #bitfinex doesnt have order side
        #amount < 0 is sell
        side = ''
        if amount > 0:
            side = 'BUY'
        if amount < 0:
            side = 'SELL'
        return side



class api_v2(object):
    _api_url = 'https://api.bitfinex.com'
    _api_key = 'lKv8on6din1xYnafQKZFzmdgx54ldgDt6Z0BxI3XBUw'
    _api_secret = 'mo00rQKOg7H7RINQdzwAFZplOdy18wt84G3JObq6KYB'

    # create nonce
    @staticmethod
    def _nonce():
        return str(int(round(time.time() * 1000000)))

    def _headers(self, path, nonce, body):

        signature = '/api' + path + nonce + body
        #print('Signing: ' + signature)

        h = hmac.new(self._api_secret.encode('utf-8'), signature.encode('utf-8'), hashlib.sha384)
        signature = h.hexdigest().lower()


        return {
            'bfx-nonce': nonce,
            'bfx-apikey': self._api_key,
            'bfx-signature': signature,
            'content-type': 'application/json'
        }


    def api_call(self, method, param={}):
        url = self._api_url + method
        nonce = self._nonce()
        raw_body = json.dumps(param)
        headers = self._headers(method, nonce, raw_body)
        #print('api_call url:', url)
        #print('api_call headers:', headers)
        #print('api_call data:', raw_body)
        return requests.post(url, headers=headers, data=raw_body, verify=True)

    def place_order(self, symbol, amount, price, side, order_type):
        symbol = 't' + symbol.upper() #format is tBTCUSD
        param = {
            'symbol': symbol,
            'amount': amount,
            'price': price,
            'side': side,
            'type': order_type
        }
        return self.api_call('/v2/auth/w/order/submit', param=param).json()

    def open_orders(self, symbol):
        return self.api_call('/v2/auth/r/orders/t{}'.format(symbol.upper()), {}).json()


    def parse_open_orders(self, data:list) -> list:
        result = []
        for o in data:
            order = Order(symbol=o[3], amount=o[6], order_type=o[8], status=o[13], price=o[16])
            result.append(order)
        return result

    def parse_submitted_order(self, data:list) -> Order:
        #reads data from server response (list)
        if data[0] == 'error':
            error_code = data[1]
            error_message = data[2]
            print(error_code, error_message)
            return None
        else:
            order = Order(symbol=data[4][0][3], amount=data[4][0][6], order_type=data[4][0][8], status=data[4][0][13], price=data[4][0][16])
            return order

class App:
    #get list of orders
    #submit an order
    def __init__(self, api):
        self.api = api

    def run(self):
        print('\nGM! This is a simple ruby app to work with orders @ bitfinex \n')
        print('enter 1 to show current open orders')
        print('enter 2 to submit new order')
        command = input()
        if command == '1':
            print('list of orders')
            self.show_my_orders()
        if command == '2':
            print('creating a new order')
            self.submit_order()


    def show_my_orders(self):
        print('Market? Available markets are: BTCUSD, ETHUSD, etc')
        market = input()
        orders = self.api.open_orders(symbol=market)
        #print(orders)
        orders = self.api.parse_open_orders(orders)
        #self.print_orders(orders)
        for order in orders:
            self.print_order(order)
        if orders == []:
            print('No open orders found for market', market)


    def print_order(self, order):
        print('\nprinting order')
        print(order.side, abs(order.amount), order.symbol, '@', order.price, 'with', order.type, 'order status is', order.status)


    def submit_order(self):
        print('Market? Available markets are: BTCUSD, ETHUSD, etc')
        #symbol = 'tBTCUSD'
        symbol = input()
        print('Amount?')
        amount = input()
        print('Price?')
        price = input()
        #price = '18018'
        print('Side? Available sides are BUY or SELL')
        #side = 'BUY'
        side = input()#.upper()
        if side in ['sell', 'SELL', 'Sell']:
            amount = -float(amount)
        amount = str(amount)
        print('Order type? Available types are: EXCHANGE LIMIT, EXCHANGE MARKET')
        order_type = input()#.upper()
        print('Plz confirm all data is correct.\n', side, amount, symbol, '@', price, 'with a', order_type, 'order. y/n?')
        input_correct = input()
        if input_correct in ['y', 'Y', 'yes', 'Yes', 'YES']:
            response = self.api.place_order(symbol, amount, price, side, order_type)
            #print(response)
            order = self.api.parse_submitted_order(response)
            if order:
                self.print_order(order)
        else:
            print('Input was not confirmed, order will not be submitted.')


client = api_v2()
#print(client.wallets())
app = App(client)
app.run()
