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
require 'lib/condor/executor'

class TestCondorIPAgent < Test::Unit::TestCase

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
