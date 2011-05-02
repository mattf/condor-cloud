# Copyright (C) 2009, 2010  Red Hat, Inc.
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

require 'deltacloud/base_driver'
require 'deltacloud/drivers/condor/client/base_models'
require 'deltacloud/drivers/condor/client/ip_agents/default'
require 'deltacloud/drivers/condor/client/executor'

module Deltacloud
  
  module Drivers
    module Condor

      require 'base64'
      require 'uuid'

      def self.query_config_server(uuid)
        # TODO: Query config server here
        { :ip_address => '127.0.0.1'}
      end

      class CondorDriver < Deltacloud::BaseDriver

        feature :instances, :user_data

        def supported_collections
          DEFAULT_COLLECTIONS - [ :storage_volumes, :storage_snapshots ]
        end

        DEFAULT_CONFIG_SERVER_ADDRESS = "127.0.0.1:5555"
        CONDOR_UUID_ID_MAPPING = File::join(File::dirname(__FILE__), 'uuid_mapper.yaml')

        def hardware_profiles(credentials, opts={})
          results = []
          new_client(credentials) do |condor|
            results = condor.hardware_profiles.collect do |hwp|
              HardwareProfile::new(hwp.name) do
                architecture 'x86_64'
                memory  hwp.memory
                cpu     hwp.cpus
                storage 100
              end
            end
          end
          filter_hardware_profiles(results, opts)
        end

        def realms(credentials, opts={})
          [
            Realm.new(
              :id => 'default',
              :name => 'Default Condor Realm',
              :limit => :unlimited,
              :state => 'AVAILABLE'
            )
          ]
        end

        def images(credentials, opts={})
          results = []
          new_client(credentials) do |condor|
            results = condor.images.collect do |image|
              Image::new(
                :id => image.id,
                :name => image.name,
                :state => image.state,
                :architecture => 'x86_64',        # TODO: Get proper value here
                :owner_id => image.owner,
                :description => image.description
              )
            end
          end
          filter_on( results, :id, opts )
        end

        def instances(credentials, opts={})
          results = []
          new_client(credentials) do |condor|
            results = condor.instances.collect do |instance|
              config = CondorDriver::query_config_server(get_uuid(instance.id))
              Instance::new(
                :id => instance.id,
                :name => instance.name,
                :realm_id => 'default',
                :instance_profile => InstanceProfile::new(instance.instance_profile.name),
                :image_id => instance.image.id,
                :public_addresses => [config[:ip_address]]
                :owner_id => instance.owner_id,
                :description => instance.name,
                :architecture => 'x86_64',
                :actions => instance_actions_for(instance.state),
                :state => instance.state
              )
            end
          end
          results = filter_on( results, :state, opts )
          filter_on( results, :id, opts )
        end

        def create_instance(credentials, image_id, opts={})
          # User data should contain this Base64 encoded configuration:
          #
          # $config_server_ip:[$uuid]
          #
          # $config_server - IP address of Configuration Server to use (eg. 192.168.1.1)
          # $uuid          - UUID to use for instance (will be used for ConfServer <-> DC
          #                  API communication)
          #
          user_data = opts[:user_data] ? Base64.decode64(opts[:user_data]) : ''
          config_server_address, vm_uuid = opts[:user_data].strip.split(':')
          vm_uuid ||= UUID::new.generate
          config_server_address ||= DEFAULT_CONFIG_SERVER_ADDRESS
          new_client(credentials) do |condor|
            image = condor.images(:id => image_id).first
            hardware_profile = condor.hardware_profiles(:id => opts[:hwp_id] || 'small')
            instance = condor.launch_instance(image, hardware_profile, { 
              :name => opts[:name] || "i-#{Time.now.to_i}", 
              :config_server_address => config_server_address,
              :uuid => vm_uuid
            }).first
            store_uuid(vm_uuid, instance.id)
            raise "Error: VM not launched" unless instance
            instance(credentials, :id => instance.id)
          end
        end

        def destroy_instance(credentials, instance_id)
          old_instance = instance(credentials, :id => instance_id)
          new_client(credentials) do |condor|
            condor.destroy_instance(instance_id)
          end
          old_instance.state = 'SHUTTING_DOWN'
          old_instance.actions = instance_actions_for(old_instance.state),
          old_instance
        end

        # TODO: You actually can't reboot VM inside Condor cloud
        # This is just a fake call, which will return instance itself
        #
        def reboot_instance(credentials, instance_id)
          instance(credentials, :id => instance_id)
        end

        define_instance_states do
          start.to( :pending )          .on( :create )
          pending.to( :running )        .automatically
          pending.to( :shutting_down )  .on( :destroy )
          running.to( :running )        .on( :reboot )
          running.to( :shutting_down )  .on( :destroy )
          shutting_down.to( :finish )   .automatically
        end

        # TODO: Add real authentication here
        #
        def valid_credentials?(credentials)
          return true
        end

        private

        def new_client(credentials)
          safely do
            yield CondorCloud::DefaultExecutor.new
          end
        end

        def store_uuid(uuid, id)
          mapper = YAML::load(open(DEFAULT_CONFIG_SERVER_ADDRESS))
          mapper[id] = uuid
          File::open(DEFAULT_CONFIG_SERVER_ADDRESS, 'w') do |f|
            f.puts YAML::dump(mapper)
          end
        end

        def get_uuid(id)
          mapper = YAML::load(open(DEFAULT_CONFIG_SERVER_ADDRESS))
          mapper[id]
        end

        def catched_exceptions_list
          {
            :auth => [],
            :error => [ RuntimeError ],
            :glob => []
          }
        end

      end
    end
  end
end
