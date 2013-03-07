require 'logger'
require 'rbconfig'

require 'rack'
require 'rack-protection'


class Gin
  VERSION = '1.0.0'

  ROOT_DIR   = File.expand_path("../..", __FILE__)         #:nodoc:
  PUBLIC_DIR = File.expand_path("../../public/", __FILE__) #:nodoc:

  class Error < StandardError; end

  class BadRequest < ArgumentError
    def http_status; 400; end
  end

  class NotFound < NameError
    def http_status; 404; end
  end


  ##
  # Change string to underscored version.

  def self.underscore str
    str = str.dup
    str.gsub!('::', '/')
    str.gsub!(/([A-Z]+?)([A-Z][a-z])/, '\1_\2')
    str.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
    str.downcase
  end


  ##
  # Create a URI query from a Hash.

  def self.build_query value, prefix=nil
    case value
    when Array
      raise ArgumentError, "no prefix given" if prefix.nil?
      value.map { |v|
        build_query(v, "#{prefix}[]")
      }.join("&")

    when Hash
      value.map { |k, v|
        build_query(v, prefix ?
          "#{prefix}[#{CGI.escape(k.to_s)}]" : CGI.escape(k.to_s))
      }.join("&")

    when String, Integer, Float, TrueClass, FalseClass
      raise ArgumentError, "value must be a Hash" if prefix.nil?
      "#{prefix}=#{CGI.escape(value.to_s)}"

    else
      prefix
    end
  end


  ##
  # Returns the full path to the file given based on the load paths.

  def self.find_loadpath file
    name = file.dup
    name << ".rb" unless name[-3..-1] == ".rb"

    return name if name[0] == ?/ && File.file?(name)

    filepath = nil

    dir = $:.find do |path|
      filepath = File.expand_path(name, path)
      File.file? filepath
    end

    dir && filepath
  end


  ##
  # Get a namespaced constant.

  def self.const_find str_or_ary, parent=Object
    const = nil
    names = Array === str_or_ary ? str_or_ary : str_or_ary.split("::")
    names.each do |name|
      const  = parent.const_get(name)
      parent = const
    end

    const
  end


  SITE_RUBY_PATH = ::Config::CONFIG["sitedir"] #:nodoc:

  ##
  # Get the application backtrace only.
  # Removes gem and Gin paths from the trace.

  def self.app_trace trace
    trace.dup.delete_if do |line|
      line.start_with?(Gin::ROOT_DIR) ||
      line.start_with?(SITE_RUBY_PATH)   ||
      Gem.path.any?{|dir| line.start_with?(dir) }
    end
  end


  require 'gin/core_ext/cgi'
  require 'gin/core_ext/gin_class'

  require 'gin/reloadable'
  require 'gin/app'
  require 'gin/router'
  require 'gin/config'
  require 'gin/request'
  require 'gin/response'
  require 'gin/stream'
  require 'gin/errorable'
  require 'gin/filterable'
  require 'gin/controller'
end
