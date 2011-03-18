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
# Module contains classes used in classadd -> Instance conversion
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

    def initialize(opts={})
      super(opts)
      @state = opts[:state] || 'AVAILABLE'
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

end
