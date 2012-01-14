module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class XpayGateway < Gateway
      
      # -> VPOSReqLight
      # ( <- VPOSResLight (KO) )
      # <- VPOSNotification (OK)
      # -> VPOSNotificationRes
      
      # static fields
      TEST_URL = 'https://www.x-pay.it/XPServlet' # test url
      LIVE_URL = 'https://www.x-pay.it/XPServlet' # test url
      TERMINAL_ID = "0000000050666666" # 16 chars # test
      ACTION_CODE = 'AUT' # AUT or AUT-CONT
      LANGUAGE = 'ITA'
      NOTIFICATION_URL = 'http://url.not'
      RESULT_URL = 'http://url.res'
      ANNULMENT_URL = 'http://url.ann'
      ERROR_URL = 'http://url.err'
      VERSION_CODE = '01.00'
      CO_PLATFORM = 'L'
      MESSAGE_TYPE = 'C00'
      MAC_KEY = '6664F1F621A5DED95C7EE8C5507A9E1F2970BCFE' # test
      
      # The countries the gateway supports merchants from as 2 digit ISO country codes
      self.supported_countries = ['IT']
      
      # The card types supported by the payment gateway
      self.supported_cardtypes = [:visa, :master, :jcb]
      
      # The homepage URL of the gateway
      self.homepage_url = 'http://www.cartasi.it/gtwpages/common/index.jsp?id=OiRGdkfJWU'
      
      # The name of the gateway
      self.display_name = 'X-Pay Cartasi'
      self.application_id = 'xpay'
      
      self.money_format = :cents
      
      CURRENCY_CODES = {
        'EUR' => '978',
        'AUD' => '036',
        'CAD' => '124',
        'HKD' => '344',
        'JPY' => '392',
        'CHF' => '756',
        'GBP' => '826',
        'USD' => '840'
      }
      
      self.default_currency = CURRENCY_CODES['EUR']

      ########################################################################################
      
      def initialize(options = {})
        @options = options
        super
      end  
      
      # VPOSReqLight
      def purchase(money, options = {})
        post = {}
        build_post(post, money, options)
        commit('sale', post)
      end                       
    
      # VPOSNotification
      def confirm
        post = {}
        post['RESPONSE'] = 0
        commit('confirm', post) # no response
      end
    
      private                       
      
      def build_post(post, money, options)
        add_static_fields(post)
        add_transaction_id(post, options)
        add_amount(post, money)
        add_currency(post, options)
        add_language(post)
        add_email(post, options) # facultative
        add_desc_order(post, options) # facultative
        # add_optional_fields(post, options) # facultative
        add_mac(post)
      end
      
      def add_static_fields(post)
        post['TERMINAL_ID'] = TERMINAL_ID
        post['ACTION_CODE'] = ACTION_CODE     
        post['NOTIFICATION_URL'] = NOTIFICATION_URL
        post['RESULT_URL'] = RESULT_URL
        post['ERROR_URL'] = ERROR_URL
        post['ANNULMENT_URL'] = ANNULMENT_URL
        post['VERSION_CODE'] = VERSION_CODE
        post['CO_PLATFORM'] = CO_PLATFORM
        post['MESSAGE_TYPE'] = MESSAGE_TYPE
      end
      
      def add_transaction_id(post, options)
        post['TRANSACTION_ID'] = "%020d" % options[:order_id] 
      end
      
      def add_amount(post, money)
        money = "%.2f" % money # 2 decimals
        money = "%09d" % money.to_s.delete('.') # 9 chars, no separators, last 2 are decimals
        post['AMOUNT'] = money
      end
      
      def add_currency(post, options)
        # xpay numeric value
        if Numeric === options[:currency]
          post['CURRENCY'] = options[:currency]
        # or 3 char code
        else
          post['CURRENCY'] = CURRENCY_CODES[options[:currency]]
        # TODO fallback
        # else
          # post['CURRENCY'] = self.default_currency
        end
      end
      
      def add_language(post)
        # TODO dynamic?
        post['LANGUAGE'] = LANGUAGE
      end
      
      def add_email(post, options)
        post['EMAIL'] = options[:email]
      end
      
      def add_desc_order(post, options)
        post['DESC_ORDER'] = options[:description]
      end
      
      def add_optional_fields(post, options)
        # post['SOME_FIELDS'] = something
      end
      
      def add_mac(post)
        string = ''
        string << "#{TERMINAL_ID}"
        string << "#{post['TRANSACTION_ID']}"
        string << "#{post['AMOUNT']}"
        string << "#{post['CURRENCY']}"
        string << "#{VERSION_CODE}"
        string << "#{CO_PLATFORM}"
        string << "#{ACTION_CODE}"
        string << "#{post['EMAIL']}"
        string << "#{MAC_KEY}"
        
        post['MAC'] = Digest::SHA1.hexdigest( string )
      end
      
      def parse(body)
        Rack::Utils.parse_query(body)
      end
      
      def post_data(post)
        post.collect { |key, value| "#{key}=#{CGI.escape(value.to_s)}" }.join("&")
      end
       
      def commit(action, post)
        request = post_data(post)
        # puts 'Request:'
        # puts request.to_yaml
        response = parse( ssl_post((test? ? TEST_URL : LIVE_URL), request ) )
        # puts 'Response:'
        # puts response
        case action
          when 'sale'
          Response.new(response['RESPONSE'] == 'TRANSACTION_OK', response['RESPONSE'], response,
            :test => @options[:test] || test?,
          )
        end
      end
      
    end
  end
end

