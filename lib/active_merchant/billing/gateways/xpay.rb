module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class XpayGateway < Gateway
      TEST_URL = 'https://example.com/test'
      LIVE_URL = 'https://www.x-pay.it/XPServlet'
      TERMINAL_ID = "" # 16 chars
      ACTION_CODE = 'AUT' # AUT or AUT-CONT
      LANGUAGE = 'ITA'
      NOTIFICATION_URL = 'http://url'
      RESULT_URL = 'http://url'
      ANNULMENT_URL = 'cac'
      ERROR_URL = 'cac'
      VERSION_CODE = '01.00'
      CO_PLATFORM = 'L'
      MESSAGE_TYPE = 'C00'
      MAC_KEY = ''
      
      
      # The countries the gateway supports merchants from as 2 digit ISO country codes
      self.supported_countries = ['IT']
      
      # The card types supported by the payment gateway
      self.supported_cardtypes = [:visa, :master, :jcb]
      
      # The homepage URL of the gateway
      self.homepage_url = 'http://www.cartasi.it/gtwpages/common/index.jsp?id=OiRGdkfJWU'
      
      # The name of the gateway
      self.display_name = 'X-Pay'
      
      self.money_format = :cents
      
      CURRENCY_CODES = {
        'EUR' => '978',
        'USD' => '840'
      }
      
      self.default_currency = CURRENCY_CODES['EUR']

      ########################################################################################
      
      def initialize(options = {})
        #requires!(options, :login, :password)
        @options = options
        super
      end  
      
      def authorize(money, creditcard, options = {})
        post = {}
        
        # add_invoice(post, options)
        # add_creditcard(post, creditcard)        
        # add_address(post, creditcard, options)        
        # add_customer_data(post, options)
        
        commit('authonly', money, post)
      end
      
      def purchase(money, creditcard, options = {})
        post = {}
        
        add_static_fields(post)
        add_transaction_id(post, options)
        add_amount(post, money)
        add_currency(post)
        add_language(post)
        add_email(post, options) # facultative
        add_desc_order(post, options) # facultative
        # add_optional_fields(post, options) # facultative
        add_mac(post)
                
        commit('sale', post)
      end                       
    
      def capture(money, authorization, options = {})
        commit('capture', money, post)
      end
    
    
      private                       
      
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
        post['TRANSACTION_ID'] = options[:order_id] 
      end
      
      def add_amount(post, money)
        money = "%.2f" % money # 2 decimals
        money = "%09d" % money.to_s.delete('.') # 9 chars, no separators, last 2 are decimals
        post['AMOUNT'] = money
      end
      
      def add_currency(post)
        # TODO dynamic?
        post['CURRENCY'] = default_currency
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
        # TODO
        mac = Digest::SHA1.hexdigest("#{TERMINAL_ID}#{TRANSACTION_ID}#{post['AMOUNT']}#{post['CURRENCY']}#{VERSION_CODE}#{CO_PLATFORM}#{ACTION_CODE}#{post['EMAIL']}#{MAC_KEY}")
        post['MAC'] = mac
      end
      
      # def add_customer_data(post, options)
      # end
# 
      # def add_address(post, creditcard, options)      
      # end
# 
      # def add_invoice(post, options)
      # end
#       
      # def add_creditcard(post, creditcard)      
      # end
#       
      # def parse(body)
      # end     
#       
      def commit(action, post)
        request = post.collect { |key, value| "{key}=#{CGI.escape(value.to_s)}" }.join("&")
        puts request
        response = ssl_post((test? ? TEST_URL : LIVE_URL), request )
        puts response
      end
# 
      # def message_from(response)
      # end
#       
      # def post_data(action, parameters = {})
      # end
    end
  end
end

