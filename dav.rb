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

require './djinn_restserver.rb'
require 'singleton'

# Namespace for the WebDAV protocol implementation
module DAV
  
  
class Resource
  
  include Djinn::Resource
  
  def local_path
    FILESYSTEM_ROOT + unslashify(decode(path))
  end

  def do_OPTIONS request, response
    response.header['DAV'] = '1,2,3'
  end
  
  def initialize path
    @path = path
  end

end


class Collection < Resource
  
  attr_reader :path
  
  def initialize path
    @path = path
  end
  
  def do_GET request, response
    response.header['Content-Type'] = 'text/plain; charset=UTF-8'
    response.write 'Hello world'
  end

end


class ResourceFactory
  include Singleton
  def [] (path)
    path = path.to_s
    case path
    when '*'
      Resource.new
    when '/'
      Collection.new path
    else
      nil
    end
  end
end


# The server class.
class RESTServer
  include Rack::Utils
=begin
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
=end
  class << self
    attr_accessor :resourceFactory
=begin # No longer necessary?
    @@instance = {}
    def instance
      @@instance[Thread.current.object_id]
    end
=end
  end
  attr_reader :env, :request
  def self.call(env)
    self.new(env).call
  end
  def initialize(p_env)
    super
    @request  = Request.new p_env
    #@@instance[Thread.current.object_id] = self
  end
  def call()
    begin
      raise 404 unless resource = resourceFactory(request)
      resource.__send__(:"method_#{request.request_method}", request)
    rescue
      Status.new($!).response
    end
  end
end # class Server
  

end # module DAV
