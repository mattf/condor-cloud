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
#
require 'rubygems'
require 'test/unit'

$:.unshift File.join(File.dirname(__FILE__), '..')


ENV['CONDOR_Q_CMD'] = "tests/bin/condor_q"
ENV['CONDOR_SUBMIT_CMD'] = "tests/bin/condor_submit"
ENV['IMAGE_STORAGE'] = "tests/images"

require 'deltacloud-condor-driver/client/executor'
require 'deltacloud-condor-driver/client/base_models.rb'
require 'deltacloud-condor-driver/client/ip_agents/default.rb'
