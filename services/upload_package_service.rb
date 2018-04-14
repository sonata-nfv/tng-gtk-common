## Copyright (c) 2015 SONATA-NFV, 2017 5GTANGO [, ANY ADDITIONAL AFFILIATION]
## ALL RIGHTS RESERVED.
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
## Neither the name of the SONATA-NFV, 5GTANGO [, ANY ADDITIONAL AFFILIATION]
## nor the names of its contributors may be used to endorse or promote
## products derived from this software without specific prior written
## permission.
##
## This work has been performed in the framework of the SONATA project,
## funded by the European Commission under Grant number 671517 through
## the Horizon 2020 and 5G-PPP programmes. The authors would like to
## acknowledge the contributions of their colleagues of the SONATA
## partner consortium (www.sonata-nfv.eu).
##
## This work has been performed in the framework of the 5GTANGO project,
## funded by the European Commission under Grant number 761493 through
## the Horizon 2020 and 5G-PPP programmes. The authors would like to
## acknowledge the contributions of their colleagues of the 5GTANGO
## partner consortium (www.5gtango.eu).
# frozen_string_literal: true
# encoding: utf-8
require 'securerandom'
require 'tempfile'
require 'fileutils'
require 'curb'
require 'net/http/post/multipart'

class UploadPackageService
  
  class << self
    attr_accessor :internal_callbacks
  end
  
  @@internal_callbacks = {}
  
  def self.call(params, content_type, unpackager_url, internal_callback_url)
    tempfile = save_file params['package'][:tempfile]
    curl = Curl::Easy.new(unpackager_url)
    curl.multipart_form_post = true
    STDERR.puts "Unpackager URL =#{unpackager_url}"
    begin
      curl.http_post(
        Curl::PostField.file('package', tempfile.path),
        Curl::PostField.content('callback_url', internal_callback_url),
        Curl::PostField.content('layer', params.fetch('layer', '')),
        Curl::PostField.content('format', params.fetch('format', ''))
      )
      # { "package_process_uuid": "03921bbe-8d9f-4cfc-b6ab-88b58cb8db7e"}
      result = JSON.parse(curl.body_str, quirks_mode: true, symbolize_names: true)
    rescue Exception => e
        STDERR.puts e.message  
        STDERR.puts e.backtrace.inspect
        return [ 500, "Internal Server Error"]
    end
    save_user_callback( result[:package_process_uuid], params['callback_url'])
    [curl.response_code.to_i, result]
  end
  
  def self.process_callback(params, external_callback_url)
    # Notifies external systems    
    begin
      curl = Curl::Easy.http_post( external_callback_url, params.to_json) do |request|
        request.headers['Accept'] = request.headers['Content-Type'] = 'application/json'
      end
    rescue Curl::Err::TimeoutError, Curl::Err::ConnectionFailedError, Curl::Err::CurlError, Curl::Err::AccessDeniedError, Curl::Err::TimeoutError, Curl::Err::TimeoutError => e
      $stderr.puts "%s - %s: %s", [Time.now.utc.to_s, self.class.name+'#'+__method__.to_s, "Failled to post to external callback #{external_callback_url}"]
    end

    # Notifies user
    $stderr.puts "package process uuid: #{params[:package_process_uuid]}"
    user_callback = get_user_callback(params[:package_process_uuid])
    return if user_callback.to_s.empty?
    begin
      resp = Curl::Easy.http_post( user_callback, params.to_json) do |http|
        http.headers['Accept'] = http.headers['Content-Type'] = 'application/json'
      end
    rescue Curl::Err::TimeoutError, Curl::Err::ConnectionFailedError, Curl::Err::HostResolutionError => e
      $stderr.puts "%s - %s: %s", [Time.now.utc.to_s, self.class.name+'#'+__method__.to_s, "Failled to post to user's callback #{user_callback}"]
    end
  end
  
  private
  def self.save_file(io)
    tempfile = Tempfile.new(random_string, '/tmp')
    io.rewind
    tempfile.write io.read
    io.rewind
    tempfile
  end
  
  def self.save_user_callback(uuid, user_callback)
    @@internal_callbacks[uuid.to_sym] = user_callback
  end
  
  def self.get_user_callback(internal_uuid)
    @@internal_callbacks[internal_uuid.to_sym]
  end

  def self.random_string
    (0...8).map { (65 + rand(26)).chr }.join
  end
end
