# Copyright (C) 2011  Red Hat, Inc.
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.  The
# ASF licenses this file to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance with the
# License.  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations
# under the License.
#

require 'tests/common'

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
      assert_not_equal('unknown', c.images(:id => '44bb0dfc4aef045cfee9a05940ed5db94d1c6970').first.owner)
      assert_equal('tests/images/RHEL5EmptyImage.img', c.images(:id => '44bb0dfc4aef045cfee9a05940ed5db94d1c6970').first.description)
    end
  end
  
end
