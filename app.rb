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

require 'rubygems'
require 'sinatra'
require 'haml'

ENV['CONDOR_Q_CMD'] = "tests/bin/condor_q"

require 'lib/condor/executor'
require 'lib/application_helper'

helpers ApplicationHelper
enable :inline_templates


before do
  content_type 'application/xml'
end

get '/' do
  redirect '/condor'
end

get '/condor' do
  haml :entrypoints
end

get '/condor/instances' do
  @instances = client.instances
  haml :instances
end

get '/condor/instances/:id' do
  @instance = client.instances(:id => params[:id]).first
  haml :instance
end

get '/condor/addresses' do
  @addresses = client.ip_agent.addresses
  haml :addresses
end


__END__

@@ entrypoints
%api
  %link{ :href => "/condor/instances", :rel => "instances"}
  %link{ :href => "/condor/addresses", :rel => "addresses"}

@@ instance
%instance{ :id => @instance.id, :href => "/condor/instances/#{@instance.id}"}
  %name=@instance.name
  %state=@instance.state
  %owner_id=@instance.owner_id
  %image{ :id => @instance.image.id}
    %name=@instance.image.name
    %state=@instance.image.state
  %realm{ :id => @instance.realm.id}
    %name=@instance.realm.id
  %instance_profile{ :cpus => @instance.instance_profile[:cpus], :memory => @instance.instance_profile[:memory]}
  %addresses{ :ip_agent => client.ip_agent.class}
    - @instance.public_addresses.each do |address|
      %address{:mac => address.mac}=address.ip

@@ instances
%instances
  - @instances.each do |instance|
    = haml(:instance, :locals => { :"@instance" => instance })

@@ address
%address
  %ip=@address.ip
  %mac=@address.mac

@@ addresses
%addresses
  - @addresses.each do |address|
    = haml(:address, :locals => { :"@address" => address })
