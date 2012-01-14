require 'test_helper'

class XpayTest < Test::Unit::TestCase
  def setup
    @gateway = XpayGateway.new()

    @credit_card = credit_card
    @amount = 666.66
    
    @options = { 
      :order_id => '1',
      :billing_address => address,
      :description => 'Store Purchase',
      :email => 'prova@freego.it',
      :currency => "EUR",
      :test => true
    }
  end
  
  def test_successful_request
    @gateway.expects(:ssl_post).returns(successful_purchase_response)
    
    assert response = @gateway.purchase(@amount, @options)
    # puts response.to_yaml
    assert_instance_of XpayGateway, @gateway
    assert_success response
    # assert_equal response.params['MAC'], @gateway.send(:add_mac, {})
    assert response.test?
  end

  def test_unsuccessful_request
    @gateway.expects(:ssl_post).returns(failed_purchase_response)
    
    assert response = @gateway.purchase(@amount, @options)
    
    assert_instance_of XpayGateway, @gateway
    assert_failure response
    assert response.test?
  end

  def test_post_data
    post = {}
    @gateway.send(:build_post, post, @amount, @options)
    assert_equal 16, post['TERMINAL_ID'].length, 'not 16 chars'
    assert_equal 20, post['TRANSACTION_ID'].length, 'not20 chars'
    assert post['ACTION_CODE'].length < 9, 'more than 8 chars'
    assert_equal 9, post['AMOUNT'].length, 'not 20 chars'
    assert !(post['AMOUNT'].include? "."), 'contains dots'
    assert !(post['AMOUNT'].include? ","), 'contains commas'
    assert_equal 3, post['CURRENCY'].length, 'not 3 chars'
    assert post['NOTIFICATION_URL'].length < 260, 'more than 260 chars'
    assert post['RESULT_URL'].length < 260, 'more than 260 chars'
    assert post['ERROR_URL'].length < 260, 'more than 260 chars'
    assert post['ANNULMENT_URL'].length < 260, 'more than 260 chars'
    assert_equal '01.00', post['VERSION_CODE'], 'not developed for this version'
    assert post['EMAIL'].length < 100, 'more than 100 chars'
    assert_match /^[a-zA-Z][\w\.-]*[a-zA-Z0-9]@[a-zA-Z0-9][\w\.-]*[a-zA-Z0-9]\.[a-zA-Z][a-zA-Z\.]*[a-zA-Z]$/, post['EMAIL'], 'invalid email address'
    assert_equal 1, post['CO_PLATFORM'].length, 'not 1 char'
    assert_equal 40, post['MAC'].length, 'not 40 chars'
  end

  private
  
  # Place raw successful response from gateway here
  def successful_purchase_response
    success_string = common_purchase_response
    success_string << "RESPONSE=TRANSACTION_OK"
  end
  
  # Place raw failed response from gateway here
  def failed_purchase_response
    fail_string = common_purchase_response
    fail_string << "RESPONSE=TRANSACTION_KO"
  end
 
   def common_purchase_response
    string = ''
    string << "TERMINAL_ID=#{@gateway.class::TERMINAL_ID}&"
    string << "TRANSACTION_ID=#{@options[:order_id]}&"
    string << "AUTH_CODE=901867&"
    string << "TRANSACTION_DATE=01/01/2012 16.55.56&"
    string << "CARD_TYPE=VISA&"
    string << "AMOUNT=#{@amount}&"
    string << "CURRENCY=#{@options[:currency]}&"
    string << "TRANSACTION_TYPE=NO_3DSECURE&"
    string << "MAC=b889211bb7f57b753419d78e75f08762a46fdd10&"
    string << "REGION=Europe&"
    string << "COUNTRY=Italy&"
    string << "PRODUCT_TYPE=Consumer&"
    string << "LIABILITY_ SHIFT=N&"
  end
  
end
