# Copyright (C) 2009 Red Hat, Inc.
#
# This program is free software; you can redistribute it and/or modify 
# it under the terms of the GNU General Public License as published by 
# the Free Software Foundation; either version 2 of the License, or 
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but 
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
# or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License 
# for more details.
#
# You should have received a copy of the GNU General Public License along 
# with this program; if not, write to the Free Software Foundation, Inc., 
# 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#

require 'pp'
require 'nokogiri'
require 'lib/condor/base_models'
require 'lib/condor/ip_agents/default'

module CondorCloud

  class DefaultExecutor

    CONDOR_Q_CMD = ENV['CONDOR_Q_CMD'] || "condor_q"
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
      inst_array = []
      (bare_xml/"/classads/c").each do |c|
        unless opts[:id].nil?
          next unless (c/'a[@n="Cmd"]/s').text.strip==opts[:id]
        end
        inst_array << Instance.new(
          :id => (c/'a[@n="Cmd"]/s').text,
          :state => Instance::convert_condor_state((c/'a[@n="JobStatus/i"]').text.to_i),
          :public_addresses => [ 
            Address.new(:mac => (c/'a[@n="JobVM_MACADDR"]/s').text, :ip => @ip_agent.find_ip_by_mac((c/'a[@n="JobVM_MACADDR"]/s').text))
          ],
          :instance_profile => {
            :cpus => (c/'a[@n="JobVM_VCPUS"]/i').text,
            :memory => (c/'a[@n="JobVMMemory"]/i').text
          },
          :owner_id => (c/'a[@n="User"]/s').text,
          :image => Image.new(:name => (c/'a[@n="VMPARAM_Kvm_Disk"]/s').text),
          :realm => Realm.new(:id => (c/'a[@n="JobVMType"]/s').text)
        )
      end
      inst_array
    end

    # List all files in ENV['STORAGE_DIRECTORY'] or fallback to '/home/cloud'
    # Conver files to CondorCloud::Image class
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


  end

end
