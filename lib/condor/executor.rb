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

require 'nokogiri'
require 'lib/condor/base_models'
require 'lib/condor/ip_agents/default'

module CondorCloud

  class DefaultExecutor

    CONDOR_Q_CMD = ENV['CONDOR_Q_CMD'] || "condor_q"

    attr_accessor :ip_agent

    def initialize(opts={}, &block)
      @ip_agent = opts[:ip_agent] || CondorCloud::DefaultIPAgent.new(opts[:ip_agent_args] || {})
      yield self if block_given?
      self
    end

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

  end

end
