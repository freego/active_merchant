require 'test_helper'

class RemoteXpayTest < Test::Unit::TestCase
  
  def setup
    @gateway = XpayGateway.new(fixtures(:xpay))
    @amount = 100
    @options = { 
      :order_id => '1',
      :billing_address => address,
      :description => 'Store Purchase',
      :email => 'buyer@example.it',
      :currency => "EUR",
      :test => true
    }
  end
  
  def test_successful_purchase
    assert response = @gateway.purchase(@amount, @options)
    assert_success response
    assert_equal response.params['MAC'], @gateway.send(:add_mac, {})
  end

end
