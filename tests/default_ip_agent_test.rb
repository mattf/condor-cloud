require 'tests/common'
require 'lib/condor/executor'

class TestCondorInstances < Test::Unit::TestCase

  def setup
    @agent = CondorCloud::DefaultIPAgent.new(:file => "config/addresses.xml")
  end

  def test_it_match_mac_address
    assert_equal "00:1A:4A:22:20:01", @agent.find_mac_by_ip('192.168.1.1')
    assert_equal nil, @agent.find_mac_by_ip('0.0.0.0')
  end

  def test_it_match_ip_address
    assert_equal "192.168.1.1", @agent.find_ip_by_mac('00:1A:4A:22:20:01')
    assert_equal nil, @agent.find_ip_by_mac('0.0.0.0')
  end
  
  
end
