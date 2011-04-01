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

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

task :default => [:test_units]

desc "Run basic tests"
Rake::TestTask.new("test_units") { |t|
  t.pattern = 'tests/*_test.rb'
  t.verbose = true
  t.warning = true
}

Rake::RDocTask.new do |rd|
    rd.main = "DESIGN.txt"
    rd.rdoc_dir = "docs"
    rd.rdoc_files.include("INSTALL.txt", "DESIGN.txt",  "deltacloud-condor-driver/**/*.rb")
  end
