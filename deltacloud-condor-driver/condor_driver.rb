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

class Instance
  attr_accessor :username
  attr_accessor :password
  attr_accessor :authn_error

  def authn_feature_failed?
    return true unless authn_error.nil?
  end
end

module Deltacloud
  
  module Drivers
    module Condor

      require 'base64'
      require 'uuid'
      require 'rest-client'
      require 'fileutils'

      def self.query_config_server(uuid)
        client = RestClient::Resource.new(CondorDriver::config_server_address)
        begin
          return { :ip_address => client["/ip/0.0.1/#{uuid}"].get(:accept => "text/plain").body }
        rescue RestClient::ResourceNotFound
          puts "Warning: IP address not found (/ip/0.0.1/#{uuid})"
          return { :ip_address => '127.0.0.1' }
        rescue
          puts "ERROR: Could not contact ConfServer (#{CondorDriver::config_server_address})"
        end
      end

      class CondorDriver < Deltacloud::BaseDriver

        feature :instances, :user_data
        feature :instances, :authentication_password

        def supported_collections
          DEFAULT_COLLECTIONS - [ :storage_volumes, :storage_snapshots ]
        end

        def self.config_server_address
          DEFAULT_CONFIG_SERVER_ADDRESS
        end

        DEFAULT_CONFIG_SERVER_ADDRESS = ENV['CONFIG_SERVER_ADDRESS'] || "10.34.32.181:4444"
        CONDOR_MAPPER_DIR = ENV['CONDOR_MAPPER_DIR'] || File::join(File::dirname(__FILE__), 'mapper')

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
                :architecture => 'x86_64',
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
              config = Condor::query_config_server(get_uuid(instance.id))
              config ||= {}
              Instance::new(
                :id => instance.id,
                :name => instance.name,
                :realm_id => 'default',
                :instance_profile => InstanceProfile::new(instance.instance_profile.name),
                :image_id => instance.image.id,
                :public_addresses => [config[:ip_address]],
                :owner_id => instance.owner_id,
                :description => instance.name,
                :architecture => 'x86_64',
                :actions => instance_actions_for(instance.state),
                :launch_time => instance.launch_time,
                :username => 'root',
                :password => opts[:password],
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
          # $otp           - One-time-password
          #
          user_data = opts[:user_data] ? Base64.decode64(opts[:user_data]) : nil
          if user_data
            config_server_address, vm_uuid, vm_otp = opts[:user_data].strip.split(':')
          end
          vm_uuid ||= UUID::new.generate
          config_server_address ||= DEFAULT_CONFIG_SERVER_ADDRESS
          vm_otp ||= vm_uuid[0..7]
          new_client(credentials) do |condor|
            image = condor.images(:id => image_id).first
            hardware_profile = condor.hardware_profiles(:id => opts[:hwp_id] || 'small')
            instance = condor.launch_instance(image, hardware_profile, { 
              :name => opts[:name] || "i-#{Time.now.to_i}", 
              :config_server_address => config_server_address,
              :uuid => vm_uuid,
              :otp => vm_otp,
            }).first
            store_uuid(vm_uuid, instance.id)
            raise "Error: VM not launched" unless instance
            instance(credentials, { :id => instance.id, :password => vm_otp })
          end
        end

        def destroy_instance(credentials, instance_id)
          old_instance = instance(credentials, :id => instance_id)
          new_client(credentials) do |condor|
            condor.destroy_instance(instance_id)
            remove_uuid(instance_id)
          end
          old_instance.state = 'PENDING'
          old_instance.actions = instance_actions_for(old_instance.state),
          old_instance
        end

        define_instance_states do
          start.to( :pending )          .automatically
          pending.to( :running )        .automatically
          pending.to( :finish )         .on(:destroy)
          running.to( :running )        .on( :reboot )
          running.to( :shutting_down )  .on( :destroy )
          pending.to( :finish )         .automatically
        end

        def valid_credentials?(credentials)
          if ( credentials.user != 'condor' ) or ( credentials.password != 'deltacloud' )
            return false
          end
          return true
        end

        private

        def new_client(credentials)
          if ( credentials.user != 'condor' ) or ( credentials.password != 'deltacloud' )
            raise Deltacloud::AuthException.new
          end
          safely do
            yield CondorCloud::DefaultExecutor.new
          end
        end

        # UUID <-> ID mapper
        def store_uuid(uuid, id)
          FileUtils.mkdir_p(CONDOR_MAPPER_DIR) unless File::directory?(CONDOR_MAPPER_DIR)
          File.open(File.join(CONDOR_MAPPER_DIR, id), 'w') do |f|
            f.puts(uuid)
          end
        end

        def get_uuid(id)
          begin
            File.open(File.join(CONDOR_MAPPER_DIR, id)).read.strip
          rescue Errno::ENOENT
            puts "Warning: UUID not found for Instance #{id} (#{File.join(CONDOR_MAPPER_DIR, id)})"
            nil
          end
        end

        def remove_uuid(id)
          begin
            FileUtils::rm(File.join(CONDOR_MAPPER_DIR, id))
          rescue
            puts "Warning: Cannot remove mapping for instance #{id} (#{File.join(CONDOR_MAPPER_DIR, id)})"
          end
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
