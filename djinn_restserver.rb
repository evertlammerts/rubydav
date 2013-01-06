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
# =DjinnIT RESTServer
# This module implements a Rack compliant server class for implementing
# RESTful web services.

# Used by HTTPStatus
require 'rexml/document'
#require './dav_server.rb'

# Namespace for the WebDAV protocol implementation
module Djinn
  

# Mixin for resource objects.
module Resource
  
  include Rack::Utils
  
  def slashify    s; '/' == s[-1,1] && s.dup         || s +  '/'; end
  def slashify!   s; '/' == s[-1,1] && s             || s << '/'; end
  def unslashify  s; '/' == s[-1,1] && s.chomp('/')  || s.dup;    end
  def unslashify! s; '/' == s[-1,1] && s.chomp!('/') || s;        end
  module_function :slashify, :slashify!, :unslashify, :unslashify!
  
  def allowed_methods
    unless @allowed_methods
      @allowed_methods ||= self.public_methods.reduce(['OPTIONS']) do
        |result, method_name|
        if ( match = /\Ado_([A-Z]+)\z/.match( method_name ) )
          result.push( match[1] )
        end
        result
      end
      @allowed_methods.push 'HEAD' if @allowed_methods.include? 'GET'
      @allowed_methods.uniq!
    end
    @allowed_methods
  end

  def http_GET request, response
    raise Djinn::HTTPStatus, '405' unless self.respond_to? :do_GET
    # TODO do something
    self.do_GET request, response
    # TODO do something
  end

  def http_HEAD request, response
    if self.respond_to? :do_HEAD
      self.do_HEAD request, response
    else
      self.http_GET request, response
    end
    response.body = []
  end
  
  # Handles an OPTIONS request.
  # 
  # An +Allow:+ header is created, listing all implemented HTTP methods
  # for this resource.
  #
  # By default, an *HTTP/1.1 204 No Content* is returned (without an entity
  # body). Users may override what's returned by implementing a method
  # #user_OPTIONS which takes two parameters:
  # 1. a Rack::Request object
  # 2. a Rack::Response object, to be modified at will.
  def http_OPTIONS request, response
    response.status = status_code :no_content
    http_method_regexp = /\Ahttp_([A-Z]+)\z/
    response.header['Allow'] = self.allowed_methods.join ', '
    self.do_OPTIONS( request, response ) if self.respond_to? :do_OPTIONS
  end
  
end


# This class has a dual nature. It inherits from RuntimeError, so that it may
# be used together with #raise.
class HTTPStatus < RuntimeError
  include Rack::Utils
  
  attr_reader :response
  
  # The general format of +message+ is: +<status> [ <space> <message> ]+
  def initialize( message )
    super message
    matches = /\A(\S+)\s*(.*)\z/.match(message.to_s)
    #raise ArgumentError, "Unexpected message format: '#{message}'"
    status = matches[1].to_i
    if 0 === status
      status = SYMBOL_TO_STATUS_CODE[ match[1].to_sym ]
      raise ArgumentError, "Unexpected message format: '#{message}'" unless status
    end
    message = matches[2]
    @response = Rack::Response.new
    @response.status = status
    @response.header['Content-Type'] = 'text/html; charset="UTF-8"'
    case status
    when 201, 301, 302, 303, 305, 307
      message = message.split /\s+/
      case message.length
      when 0
        message = ''
      when 1
        message = "<p><a href=\"#{message[0]}\">#{message[0]}</a></p>"
        @response.header['Location'] = message
      else
        message = '<ul>' + message.collect {
          |url|
          "<li><a href=\"#{url}\">#{url}</a></li>"
        }.join + '</ul>'
      end
    when 405
      message = message.split /\s+/
      @response.header['Allow'] = message.join ', '
      message = '<h2>Allowed methods:</h2><ul>' + message.collect {
          |method|
          "<li>#{method}</li>"
        }.join("\n") + '</ul>'
    end
    begin
      REXML::Document.new \
        '<?xml version="1.0" encoding="UTF-8" ?>' +
        '<div>' + message + '</div>'
    rescue
      message = escape_html message
    end
    @response.write self.class.template.call( status, message )
  end
  
  DEFAULT_TEMPLATE = lambda do
    | status_code, xhtml_message |
    status_code = status_code.to_i
    xhtml_message = xhtml_message.to_s
    '<?xml version="1.0" encoding="UTF-8"?>' +
    '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">' +
    '<html><head><title>HTTP/1.1 ' +
    status_code.to_s + ' ' + HTTP_STATUS_CODES[status_code] +
    '</title></head><body><h1>HTTP/1.1 ' +
    status_code.to_s + ' ' + HTTP_STATUS_CODES[status_code] +
    '</h1>' + xhtml_message + '</body></html>'
  end
  
  # The passed block must accept two arguments:
  # 1. *int* a status code
  # 2. *string* an xhtml fragment
  # and return a string
  def self.template(&block)
    @template ||= block || DEFAULT_TEMPLATE
  end
  
end


# Rack middleware, inspired by Rack::RelativeRedirect. Differences:
# - uses Rack::Utils::base_uri for creating absolute URIs.
# - the +Location:+ header is always rectified, independent of the HTTP status.
class RelativeLocation
  
  # Initialize a new RelativeRedirect object with the given arguments.  Arguments:
  # * app : The next middleware in the chain.  This is always called.
  # * &block : If provided, it is called with the environment and the response
  #   from the next middleware. It should return a string representing the scheme
  #   and server name (such as 'http://example.org').
  def initialize(app)
    @app = app
  end

  # Call the next middleware with the environment.  If the request was a
  # redirect (response status 301, 302, or 303), and the location header does
  # not start with an http or https url scheme, call the block provided by new
  # and use that to make the Location header an absolute url.  If the Location
  # does not start with a slash, make location relative to the path requested.
  def call(env)
    res = @app.call(env)
    if ( location = res[1]['Location'] ) and
       ! %r{\Ahttps?://}.match(location)
      request = Rack::Request.new env
      unless '/' == location[0...1]
        path = request.path.dup
        path[ %r{[^/]*\z} ] = ''
        location = File.expand_path(location, path )
      end
      res[1]['Location'] = request.base_url + location
    end
    res
  end

end


# The server class.
class RESTServer
  attr_reader :request
  @@instances = {}
  
  # This may not actually be necessary. See also #call, which populates class
  # variable @@instances.
  def self.current
    @@instances[Thread.current.object_id]
  end
  
  # Prototype constructor. The supplied +resource_factory+ must respond to
  # method #[]. This method will be called with a path string, and must return
  # a Resource object.
  def initialize(p_resource_factory)
    super
    @resource_factory = p_resource_factory
  end
  
  def resource(p_path = nil)
    p_path ||= request.path
    @resource_factory[p_path]
  end
  
  def call(p_env)
    server = dup
    @@instances[Thread.current.object_id] = server
    begin
      server.call! p_env # This is what is returned.
    ensure
      @@instances.delete Thread.current.object_id
    end
  end
  
  def call!(p_env)
    @request = Rack::Request.new p_env
    response = Rack::Response.new
    begin
      raise HTTPStatus, '404' unless resource = @resource_factory[request.path]
      if resource.respond_to? :"http_#{request.request_method}"
        resource.__send__( :"http_#{request.request_method}", request, response )
      elsif resource.respond_to? :"do_#{request.request_method}"
        resource.__send__( :"do_#{request.request_method}", request, response )
      else
        raise( HTTPStatus, '405 ' + resource.allowed_methods.join( ' ' ) )
      end
      response.finish
    rescue HTTPStatus => s
      s.response.body = [] if 'HEAD' == request.request_method
      s.response.finish
    end
  end
  
end # class RESTServer
  

end # module Djinn

=begin
 BasicObject
  Exception
    IRB::Abort
    NoMemoryError
    ScriptError
      LoadError
        Gem::LoadError
      NotImplementedError
      SyntaxError
    SecurityError
    SignalException
      Interrupt
    StandardError
      ArgumentError
      EncodingError
        Encoding::CompatibilityError
        Encoding::ConverterNotFoundError
        Encoding::InvalidByteSequenceError
        Encoding::UndefinedConversionError
      Exception2MessageMapper::ErrNotRegisteredException
      FiberError
      IOError
        EOFError
      IRB::CantChangeBinding
      IRB::CantReturnToNormalMode
      IRB::CantShiftToMultiIrbMode
      IRB::IllegalParameter
      IRB::IrbAlreadyDead
      IRB::IrbSwitchedToCurrentThread
      IRB::NoSuchJob
      IRB::NotImplementedError
      IRB::Notifier::ErrUndefinedNotifier
      IRB::Notifier::ErrUnrecognizedLevel
      IRB::SLex::ErrNodeAlreadyExists
      IRB::SLex::ErrNodeNothing
      IRB::UndefinedPromptMode
      IRB::UnrecognizedSwitch
      IndexError
        KeyError
        StopIteration
      LocalJumpError
      Math::DomainError
      NameError
        NoMethodError
      RangeError
        FloatDomainError
      RegexpError
      RubyLex::AlreadyDefinedToken
      RubyLex::SyntaxError
      RubyLex::TerminateLineInput
      RubyLex::TkReading2TokenDuplicateError
      RubyLex::TkReading2TokenNoKey
      RubyLex::TkSymbol2TokenNoKey
      RuntimeError
        Gem::Exception
          Gem::CommandLineError
          Gem::DependencyError
          Gem::DependencyRemovalException
          Gem::DocumentError
          Gem::EndOfYAMLException
          Gem::FilePermissionError
          Gem::FormatException
          Gem::GemNotFoundException
          Gem::GemNotInHomeException
          Gem::InstallError
          Gem::InvalidSpecificationException
          Gem::OperationNotSupportedError
          Gem::RemoteError
          Gem::RemoteInstallationCancelled
          Gem::RemoteInstallationSkipped
          Gem::RemoteSourceException
          Gem::VerificationError
      SystemCallError
      ThreadError
      TypeError
      ZeroDivisionError
    SystemExit
      Gem::SystemExitException
    SystemStackError
    fatal
 
=end