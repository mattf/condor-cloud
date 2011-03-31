#
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

class TestCondorInstances < Test::Unit::TestCase

  def setup
    @condor = CondorCloud::DefaultExecutor
  end
  
  def test_list_of_instances
    @condor.new do |c|
      assert_instance_of(Array, c.instances)
      assert_equal(1, c.instances.size)
      assert_instance_of(CondorCloud::Instance, c.instances.first)
      assert_instance_of(CondorCloud::Realm, c.instances.first.realm)
    end
  end

  def test_first_instance_image
    @condor.new do |c|
      assert_instance_of(CondorCloud::Image, c.instances.first.image)
      assert_equal('7de6086a9e6ff76dd8bd37c9e770ab4f5cb4649a', c.instances.first.image.id)
      assert_equal('fedora_work_machine-clone-img', c.instances.first.image.name)
    end
  end

  def test_first_instance_attributes
    @condor.new do |c|
      assert_equal('1300202231', c.instances.first.id)
      assert_equal('kvm_test2', c.instances.first.name)
      assert_instance_of(CondorCloud::HardwareProfile, c.instances.first.instance_profile)
      assert_equal('RUNNING', c.instances.first.state)
      assert_instance_of(CondorCloud::Address, c.instances.first.public_addresses.first)
      assert_equal('', c.instances.first.public_addresses.first.ip)
      assert_equal('52:54:00:ab:90:41', c.instances.first.public_addresses.first.mac)
    end
  end

  def test_filtering_instances_by_id
    @condor.new do |c|
      assert_instance_of(Array, c.instances(:id => '1300202231'))
      assert_equal(1, c.instances(:id => '1300202231').size)
      assert_equal(0, c.instances(:id => '---- TEST ----').size)
    end
  end

  def test_launch_instance
    @image = CondorCloud::Image.new(:name => 'Fedora14EmptyImage.img', :description => 'tests/images/Fedora14EmptyImage.img')
    @hardware_profile = CondorCloud::HardwareProfile.new(:name => 'medium')
    @condor.new do |c|
      instance = c.launch_instance(@image, @hardware_profile, :name => 'kvm_test2')
      assert_instance_of(Array, instance)
      assert_instance_of(CondorCloud::Instance, instance.first)
      assert_instance_of(CondorCloud::HardwareProfile, instance.first.instance_profile)
      assert_equal('medium', instance.first.instance_profile.name)
      assert_equal('1024', instance.first.instance_profile.memory)
      assert_equal('2', instance.first.instance_profile.cpus)
      assert_instance_of(CondorCloud::Image, instance.first.image)
      assert_equal('7de6086a9e6ff76dd8bd37c9e770ab4f5cb4649a', instance.first.image.id)
      assert_equal('fedora_work_machine-clone-img', instance.first.image.name)
      assert_equal('', instance.first.public_addresses.first.ip)
      assert_equal('RUNNING', instance.first.state)
    end
  end

end
