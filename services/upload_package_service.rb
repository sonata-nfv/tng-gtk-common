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
  
  EXTERNAL_CALLBACK_URL = ENV.fetch('EXTERNAL_CALLBACK_URL', '')
  UNPACKAGER_URL= ENV.fetch('UNPACKAGER_URL', '')
  ERROR_UNPACKAGER_URL_NOT_PROVIDED={error: 'You must provide the un-packager URL as the UNPACKAGER_URL environment variable'}
  
  @@internal_callbacks = {}
  
  def self.call(params, content_type, internal_callback_url)
    return [400, ERROR_UNPACKAGER_URL_NOT_PROVIDED.to_json] if UNPACKAGER_URL == ''
    
    tempfile = save_file params['package'][:tempfile]
    curl = Curl::Easy.new(UNPACKAGER_URL)
    curl.multipart_form_post = true
    begin
      curl.http_post(
        Curl::PostField.file('package', tempfile.path),
        Curl::PostField.content('callback_url', internal_callback_url),
        Curl::PostField.content('layer', params.fetch('layer', '')),
        Curl::PostField.content('format', params.fetch('format', ''))
      )
      # { "package_process_uuid": "03921bbe-8d9f-4cfc-b6ab-88b58cb8db7e", "status": status, "error_msg": p.error_msg}
      body = curl.body_str
      result = JSON.parse(body, quirks_mode: true, symbolize_names: true)
      result
    rescue Exception => e
        STDERR.puts e.message  
        STDERR.puts e.backtrace.inspect
        return [ 500, "Internal Server Error"]
    end
    save_user_callback( result[:package_process_uuid], params['callback_url'])
    [curl.response_code.to_i, result]
  end
  
  def self.process_callback(params)
    save_result(params)
    notify_external_systems(params) unless EXTERNAL_CALLBACK_URL == ''
    notify_user(params)
  end
  
  private
  def self.save_result(result)
    process_id = result[:package_process_uuid]
    @@internal_callbacks[process_id][:result]= result
  end
  
  def self.notify_external_systems(params)
    begin
      curl = Curl::Easy.http_post( EXTERNAL_CALLBACK_URL, params.to_json) do |request|
        request.headers['Accept'] = request.headers['Content-Type'] = 'application/json'
      end
    rescue Curl::Err::TimeoutError, Curl::Err::ConnectionFailedError, Curl::Err::CurlError, Curl::Err::AccessDeniedError, Curl::Err::TimeoutError, Curl::Err::TimeoutError => e
      STDERR.puts "%s - %s: %s", [Time.now.utc.to_s, self.class.name+'#'+__method__.to_s, "Failled to post to external callback #{EXTERNAL_CALLBACK_URL}"]
    end
  end
  
  def self.notify_user(params)
    user_callback = @@internal_callbacks[params[:package_process_uuid]][:user_callback]
    return if user_callback.to_s.empty?
    begin
      resp = Curl::Easy.http_post( user_callback, params.to_json) do |http|
        http.headers['Accept'] = http.headers['Content-Type'] = 'application/json'
      end
    rescue Curl::Err::TimeoutError, Curl::Err::ConnectionFailedError, Curl::Err::HostResolutionError => e
      STDERR.puts "%s - %s: %s", [Time.now.utc.to_s, self.class.name+'#'+__method__.to_s, "Failled to post to user's callback #{user_callback}"]
    end
  end

  def self.save_file(io)
    tempfile = Tempfile.new(random_string, '/tmp')
    io.rewind
    tempfile.write io.read
    io.rewind
    tempfile
  end
  
  def self.save_user_callback(uuid, user_callback)
    @@internal_callbacks[uuid.to_sym] = { user_callback: user_callback, result: nil}
  end
  
  def self.random_string
    (0...8).map { (65 + rand(26)).chr }.join
  end
end
