require 'tests/common'
require 'lib/condor/executor'

class TestCondorHardwareProfiles < Test::Unit::TestCase

  def setup
    @condor = CondorCloud::DefaultExecutor
  end

  def test_it_returns_all_hardware_profiles
    @condor.new do |c|
      assert_instance_of(Array, c.hardware_profiles)
      assert_instance_of(CondorCloud::HardwareProfile, c.hardware_profiles.first)
      assert_equal(3, c.hardware_profiles.size)
    end
  end

end
