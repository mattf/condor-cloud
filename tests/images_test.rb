require 'tests/common'
require 'lib/condor/executor'

class TestCondorImages < Test::Unit::TestCase

  def setup
    @condor = CondorCloud::DefaultExecutor
  end
  
  def test_list_of_images
    @condor.new do |c|
      assert_instance_of(Array, c.images)
      assert_instance_of(CondorCloud::Image, c.images.first)
      assert_equal(4, c.images.size)
    end
  end

  def test_get_image_by_id
    @condor.new do |c|
      assert_instance_of(Array, c.images(:id => '44bb0dfc4aef045cfee9a05940ed5db94d1c6970'))
      assert_instance_of(CondorCloud::Image, c.images(:id => '44bb0dfc4aef045cfee9a05940ed5db94d1c6970').first)
      assert_equal(1, c.images(:id => '44bb0dfc4aef045cfee9a05940ed5db94d1c6970').size)
    end
  end

  def test_image_attributes
    @condor.new do |c|
      assert_equal('rhel5emptyimage-img', c.images(:id => '44bb0dfc4aef045cfee9a05940ed5db94d1c6970').first.name)
      assert_equal('AVAILABLE', c.images(:id => '44bb0dfc4aef045cfee9a05940ed5db94d1c6970').first.state)
      assert_equal('tests/images/RHEL5EmptyImage.img', c.images(:id => '44bb0dfc4aef045cfee9a05940ed5db94d1c6970').first.description)
    end
  end

  
end
