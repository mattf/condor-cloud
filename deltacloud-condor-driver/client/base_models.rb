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

require 'digest/sha1'

module CondorCloud

  class Base

    attr_accessor :id
    attr_accessor :name
    
    def initialize(opts)
      @id, @name = opts[:id], opts[:name]
      @name ||= @id
    end

  end

  class Instance < Base
    
    attr_accessor :state
    attr_accessor :image
    attr_accessor :realm
    attr_accessor :public_addresses
    attr_accessor :instance_profile
    attr_accessor :owner_id

    def initialize(opts={})
      super(opts)
      @state, @image = opts[:state], opts[:image]
      @instance_profile, @realm = opts[:instance_profile], opts[:realm]
      @public_addresses = opts[:public_addresses]
      @owner_id = opts[:owner_id]
      self
    end

    def self.convert_condor_state(state_id)
      case state_id
        when 0,1,5 then 'PENDING'
        when 2     then 'RUNNING'
        when 3,4   then 'SHUTTING_DOWN'
        else raise "Unknown Condor state (#{state_id})"
      end
    end

  end

  class Realm < Base; end

  class Image < Base

    attr_accessor :state
    attr_accessor :description
    attr_accessor :owner

    # Image ID is automatically created using SHA1 hash from image name
    # since filename must be unique in directory
    def initialize(opts={})
      super(opts)
      @state = opts[:state] || 'AVAILABLE'
      @owner = opts[:owner] || 'unknown'
      @name = @name.split(':').first
      @description = opts[:description] || ''
      @id = Digest::SHA1.hexdigest(@name).to_s
      self
    end

  end

  class Address
    attr_accessor :ip
    attr_accessor :mac

    def initialize(opts={})
      @ip, @mac = opts[:ip], opts[:mac]
    end
  end

  class HardwareProfile < Base
    
    attr_accessor :memory
    attr_accessor :cpus
    attr_accessor :name

    # You can create hardware profile using { :name => "small|medium|large" }
    # or specifying :memory and :cpus
    #
    def initialize(opts={})
      if opts[:name]
        @memory, @cpus = case opts[:name]
                          when 'small' then ['512', '1']
                          when 'medium' then ['1024', '2']
                          when 'large' then ['2047', '4']
                          else raise "Unknown HardwareProfile name '#{opts[:name]}'"
                        end
      else
        @memory, @cpus = opts[:memory], opts[:cpus]
      end
      @name = convert_properties_to_name(:memory => @memory, :cpus => @cpus)
      @id = @name
      self
    end

    private

    def convert_properties_to_name(properties)
      case properties
        when { :memory => '512', :cpus => '1' } then 'small'
        when { :memory => '1024', :cpus => '2' } then 'medium'
        when { :memory => '2047', :cpus => '4' } then 'large'
        else 'unknown'
      end
    end

  end

end
