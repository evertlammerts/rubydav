#--
# Copyright ©2011-2012 Pieter van Beek <pieterb@sara.nl>
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#++
# =DAV
# *DAV* is an implementation of the WebDAV protocol in Ruby.
#
# +dav.rb+ is the main include file for the WebDAV server library. Users of
# the library should only include this file, with
#   require 'dav.rb'

#require './dav_server.rb'
require 'sinatra/base'
require 'sinatra/reloader'

# Namespace for the WebDAV protocol implementation
module DAV
  
  
# The server class.
class Server < Sinatra::Base
  WEBDAV_METHODS = [
    'OPTIONS'.freeze,
    'GET'.freeze,
    'HEAD'.freeze,
    'PUT'.freeze,
    'POST'.freeze,
    'DELETE'.freeze,
    'PROPFIND'.freeze,
    'PROPPATCH'.freeze,
    'ACL'.freeze,
    'MKCOL'.freeze,
    'LOCK'.freeze,
    'UNLOCK'.freeze,
  ].freeze
  def self.route_all(path, opts={}, methods=WEBDAV_METHODS, &block)
    conditions = @conditions
    methods.each do |method|
      @conditions = conditions.dup
      route(method, path, opts, &block)
    end
  end
  attr_accessor :resource
  #register Sinatra::WebDAV
  configure(:development) do; register Sinatra::Reloader; end
  configure(:development, :test, :production) do; enable :logging; end
  enable :static
  set :default_encoding, 'UTF-8'
  before do; $logger = logger; end
  
  route_all '*' do
    public_send(:"method_#{request.method}")
    [ 200, { 'Content-Type' => 'text/plain' }, ["Hallo wereld"] ]
  end

end # class Server
  

end # module DAV
