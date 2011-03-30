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

require 'pp'
require 'nokogiri'
require 'etc'
require 'tempfile'

module CondorCloud

  class DefaultExecutor

    CONDOR_Q_CMD = ENV['CONDOR_Q_CMD'] || "condor_q"
    CONDOR_RM_CMD = ENV['CONDOR_RM_CMD'] || "condor_rm"
    CONDOR_SUBMIT_CMD = ENV['CONDOR_SUBMIT_CMD'] || 'condor_submit'
    IMAGE_STORAGE = ENV['IMAGE_STORAGE'] || '/home/cloud/images'

    attr_accessor :ip_agent

    def initialize(opts={}, &block)
      @ip_agent = opts[:ip_agent] || CondorCloud::DefaultIPAgent.new(opts[:ip_agent_args] || {})
      yield self if block_given?
      self
    end

    # List instances using ENV['CONDOR_Q_CMD'] command.
    # Retrieve XML from this command and parse it uring Nokogiri. Then this XML
    # is converted to CondorCloud::Instance class
    #
    # @opts - This Hash can be used for filtering instances using :id => 'instance_id'
    #
    def instances(opts={})
      bare_xml = Nokogiri::XML(`#{CONDOR_Q_CMD} -xml`)
      parse_condor_q_output(bare_xml, opts)
    end

    # List all files in ENV['STORAGE_DIRECTORY'] or fallback to '/home/cloud/images'
    # Convert files to CondorCloud::Image class
    #
    # @opts - This Hash can be used for filtering images using :id => 'SHA1 of
    # name'
    #
    def images(opts={})
      Dir["#{IMAGE_STORAGE}/*"].collect do |file|
        image = Image.new(
          :name => File::basename(file).downcase.tr('.', '-'),
          :owner => Etc.getpwuid(File.stat(file).uid).name,
          :description => file
        ) 
        next if opts[:id] and opts[:id]!=image.id
        image
      end.compact
    end

    # Launch a new instance in Condor cloud using ENV['CONDOR_SUBMIT_CMD'].
    # Return CondorCloud::Instance.
    # 
    # @image  - Expecting CondorCloud::Image here
    # @hardware_profile - Expecting CondorCloud::HardwareProfile here
    #
    # @opts - You can specify additional parameters like :name here
    #
    def launch_instance(image, hardware_profile, opts={})
      raise "Image object must be not nil" unless image 
      raise "HardwareProfile object must be not nil" unless hardware_profile
      opts[:name] ||= "i-#{Time.now.to_i}"

      # This needs to be determined by the mac/ip translation stuff.
      # We need to call into it and have it return these variables, or at least the MAC if not the IP.
      mac_addr = '00:1A:4A:22:20:01'
      ip_addr = '172.31.0.101'

      # I use the 2>&1 to get stderr and stdout together because popen3 does not support
      # the ability to get the exit value of the command in ruby 1.8.
      pipe = IO.popen("#{CONDOR_SUBMIT_CMD} 2>&1", "w+")
      pipe.puts "universe=vm"
      pipe.puts "vm_type=kvm"
      pipe.puts "vm_memory=#{hardware_profile.memory}"
      pipe.puts "request_cpus=#{hardware_profile.cpus}"
      pipe.puts "vm_disk=#{image.description}:null:null"
      pipe.puts "executable=#{image.description}"
      pipe.puts "vm_macaddr=#{mac_addr}"

      # Only set the ip if it is available, and this should depend on the IP mapping used.
      # With the fixed mapping method we know the IP address right away before we start the
      # instance, so fill it in here.  If it is not set I think we should set it to an empty
      # string and we'll fill it in later using a condor tool to update the job.
      pipe.puts "+vm_ipaddr=\"#{ip_addr}\""
      pipe.puts '+HookKeyword="CLOUD"'
      pipe.puts "+Cmd=\"#{opts[:name]}\""
      # Really the image should not be a full path to begin with I think..
      pipe.puts "+cloud_image=\"#{File.basename(image.description)}\""
      pipe.puts "+VM_XML=\"<domain type='kvm'><name>{NAME}</name><memory>#{hardware_profile.memory.to_i * 1024}</memory><vcpu>#{hardware_profile.cpus}</vcpu><os><type arch='x86_64' machine='pc-0.13'>hvm</type><boot dev='hd'/></os><features><acpi/><apic/><pae/></features><clock offset='utc'/><on_poweroff>destroy</on_poweroff><on_reboot>restart</on_reboot><on_crash>restart</on_crash><devices><emulator>/usr/bin/qemu-kvm</emulator><disk type='file' device='disk'><source file='{DISK}'/><target dev='vda' bus='virtio'/><driver name='qemu' type='qcow2'/></disk><interface type='bridge'><mac address='#{mac_addr}'/><source bridge='vnet0'/><alias name='net0'/></interface><graphics type='vnc' port='5900' autoport='yes' keymap='en-us'/></devices></domain>\""
      pipe.puts "queue"
      pipe.puts ""
      pipe.close_write
      out = pipe.read
      pipe.close
      raise ("Error starting VM in condor_submit: #{out}") if $? != 0

      bare_xml = Nokogiri::XML(`#{CONDOR_Q_CMD} -xml`)
      parse_condor_q_output(bare_xml, :name => opts[:name])
    end

    def destroy_instance(instance_id)
      bare_xml = Nokogiri::XML(`#{CONDOR_Q_CMD} -xml`)
      cluster_id = (bare_xml/'/classads/c/a[@n="GlobalJobId"]/s').collect do |id|
        id.text.split('#')[1] if id.text.split('#').last==instance_id
      end.compact.first
      `#{CONDOR_RM_CMD} #{cluster_id}`
    end

    # List hardware profiles available for Condor.
    # Basically those profiles are static 'small', 'medium' and 'large'
    #
    # Defined as:
    #
    #    when { :memory => '512', :cpus => '1' } then 'small'
    #    when { :memory => '1024', :cpus => '2' } then 'medium'
    #    when { :memory => '2047', :cpus => '4' } then 'large'
    #
    # @opts - You can filter hardware_profiles using :id
    #
    def hardware_profiles(opts={})
      return [
        HardwareProfile.new(:name => 'small'),
        HardwareProfile.new(:name => 'medium'),
        HardwareProfile.new(:name => 'large')
      ] unless opts[:id]
      HardwareProfile.new(:name => opts[:id])
    end

    private

    def parse_condor_q_output(bare_xml, opts={})
      inst_array = []
      (bare_xml/"/classads/c").each do |c|
        unless opts[:id].nil?
          next unless (c/'a[@n="GlobalJobId"]/s').text.strip.split('#').last==opts[:id]
        end
        unless opts[:name].nil?
          next unless (c/'a[@n="Cmd"]/s').text.strip==opts[:name]
        end
        # Even with the checks above this can still fail because there may be other condor jobs
        # in the queue formatted in ways we don't know.
        begin
          inst_array << Instance.new(
            :id => (c/'a[@n="GlobalJobId"]/s').text.strip.split('#').last,
            :name => (c/'a[@n="Cmd"]/s').text.strip,
            :state => Instance::convert_condor_state((c/'a[@n="JobStatus"]/i').text.to_i),
            :public_addresses => [
              Address.new(:mac => (c/'a[@n="JobVM_MACADDR"]/s').text, :ip => (c/'a[@n="vm_ipaddr"]/s').text)
            ],
            :instance_profile => HardwareProfile.new(:memory => (c/'a[@n="JobVMMemory"]/i').text, :cpus => (c/'a[@n="JobVM_VCPUS"]/i').text),
            :owner_id => (c/'a[@n="User"]/s').text,
            :image => Image.new(:name => File::basename((c/'a[@n="VMPARAM_vm_Disk"]/s').text.split(':').first).downcase.tr('.', '-')),
            :realm => Realm.new(:id => (c/'a[@n="JobVMType"]/s').text)
          )
        rescue Exception => e
          puts "Caught exception: #{e}"
          puts e.message
          puts e.backtrace
          # Be nice to log something here in case we start getting silent failures.
        end
      end
      inst_array
    end

  end
end
