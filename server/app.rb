require 'rubygems'

gem 'haml'
gem 'sinatra', '>=1.0.0'

require 'sinatra'
require 'haml'

enable :inline_templates

before do
  content_type "application/xml"
end

get "/" do
  redirect "/condor"
end

get "/condor" do
  haml :index
end

# Get list of instances in XML form
get "/condor/instances" do
  `../list_instances.sh`
end

# Get list of all MAC->IP pairs
get "/condor/addresses" do
  File::open("addresses.xml", "r").read
end

__END__

@@ layout
%api
  = yield

@@ index
%link{ :href => "/condor/instances", :rel => "instances"}
%link{ :href => "/condor/addresses", :rel => "addresses"}
