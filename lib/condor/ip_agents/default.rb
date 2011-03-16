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

module CondorCloud


  class DefaultIPAgent
    
    def initialize(opts={})
      @mappings = Nokogiri::XML(File.open(opts[:file] || File.join('config', 'addresses.xml')))
    end

    def find_ip_by_mac(mac)
      t = (@mappings/"/addresses/address[@mac='#{mac}']").text
      t.empty? ? nil : t
    end

    def find_mac_by_ip(ip)
      (@mappings/"/addresses/address[.='#{ip}']").first[:mac] rescue nil
    end

    def addresses
      (@mappings/'/addresses/address').collect { |a| Address.new(:ip => a.text.strip, :mac => a[:mac]) }
    end

  end

end
