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

require 'rake'

Gem::Specification.new do |s|
  s.author = 'Red Hat, Inc.'
  s.homepage = "http://git.fedorahosted.org/git/?p=condor-cloud.git;a=summary"
  s.email = 'aeolus-devel@lists.fedorahosted.org'
  s.name = 'condor-cloud'
  s.license = 'ASL 2.0'

  s.description = <<-EOF
    Implementation of a private cloud using Condor
  EOF

  s.version = '0.0.1'
  s.date = Time.now
  s.summary = %q{Implementation of a private cloud using Condor}
  s.files = FileList[
    'Rakefile',
    'README',
    'COPYING',
    '*.gemspec',
    '*.rb',
    'config/*',
    'lib/**/*.rb',
    'tests/**/*'
  ].to_a

  s.test_files= Dir.glob("tests/*_test.rb")
  s.extra_rdoc_files = Dir["COPYING"]
  s.add_dependency('rake')
  s.add_dependency('nokogiri')

end
