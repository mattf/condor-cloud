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

require 'pp'
require 'nokogiri'
require 'tempfile'
require 'condor/base_models'
require 'condor/ip_agents/default'

module CondorCloud

  class DefaultExecutor

    CONDOR_Q_CMD = ENV['CONDOR_Q_CMD'] || "condor_q"
    CONDOR_SUBMIT_CMD = ENV['CONDOR_SUBMIT_CMD'] || 'condor_submit'
    IMAGE_STORAGE = ENV['IMAGE_STORAGE'] || '/home/cloud'

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

    # List all files in ENV['STORAGE_DIRECTORY'] or fallback to '/home/cloud'
    # Convert files to CondorCloud::Image class
    #
    # @opts - This Hash can be used for filtering images using :id => 'SHA1 of
    # name'
    #
    def images(opts={})
      Dir["#{IMAGE_STORAGE}/*"].collect do |file|
        image = Image.new(
          :name => File::basename(file.downcase.tr('.', '-')),
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
      opts[:name] ||= "i-#{Time.now.to_i}"
      job=::Tempfile.open('condor_job')
      job.puts "universe = vm"
      job.puts "vm_type = kvm"
      job.puts "vm_memory = #{hardware_profile.memory}"
      job.puts "request_cpus = #{hardware_profile.cpus}"
      job.puts "kvm_disk = /dev/null:null:null"
      job.puts "executable = #{image.description}"
      job.puts '+HookKeyword="CLOUD"'
      job.puts "+Cmd='#{opts[:name]}'"
      job.puts "+VM_XML=\"<domain type='kvm'><name>{NAME}</name><memory>$((#{hardware_profile.memory} * 1024))</memory><vcpu>#{hardware_profile.cpus}</vcpu><os><type arch='i686' machine='pc-0.11'>hvm</type><boot dev='hd'/></os><features><acpi/><apic/><pae/></features><clock offset='utc'/><on_poweroff>destroy</on_poweroff><on_reboot>restart</on_reboot><on_crash>restart</on_crash><devices><emulator>/usr/bin/qemu-kvm</emulator><disk type='file' device='disk'><source file='{DISK}'/><target dev='hda' bus='ide'/><driver name='qemu' type='qcow2'/></disk><interface type='network'><source network='default'/><model type='e1000'/></interface><graphics type='vnc' port='5900' autoport='yes' keymap='en-us'/></devices></domain>\""
      job.puts "queue"
      job.puts ""
      `#{CONDOR_SUBMIT_CMD} #{job.path}`
      job.close
      bare_xml = Nokogiri::XML(`#{CONDOR_Q_CMD} -xml`)
      parse_condor_q_output(bare_xml, :name => opts[:name])
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
        inst_array << Instance.new(
          :id => (c/'a[@n="GlobalJobId"]/s').text.strip.split('#').last,
          :name => (c/'a[@n="Cmd"]/s').text.strip,
          :state => Instance::convert_condor_state((c/'a[@n="JobStatus/i"]').text.to_i),
          :public_addresses => [ 
            Address.new(:mac => (c/'a[@n="JobVM_MACADDR"]/s').text, :ip => @ip_agent.find_ip_by_mac((c/'a[@n="JobVM_MACADDR"]/s').text))
          ],
          :instance_profile => HardwareProfile.new(:memory => (c/'a[@n="JobVMMemory"]/i').text, :cpus => (c/'a[@n="JobVM_VCPUS"]/i').text),
          :owner_id => (c/'a[@n="User"]/s').text,
          :image => Image.new(:name => (c/'a[@n="VMPARAM_Kvm_Disk"]/s').text),
          :realm => Realm.new(:id => (c/'a[@n="JobVMType"]/s').text)
        )
      end
      inst_array
    end

  end
end
