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
#require 'net/http/post/multipart'
#require 'rest_client'

class UploadPackageService
  
  class << self
    attr_accessor :internal_callbacks
  end
  
  INTERNAL_CALLBACK_URL = ENV.fetch('INTERNAL_CALLBACK_URL', 'http://tng-gtk-common:5000/packages/on-change')
  EXTERNAL_CALLBACK_URL = ENV.fetch('EXTERNAL_CALLBACK_URL', '')
  UNPACKAGER_URL= ENV.fetch('UNPACKAGER_URL', '')
  ERROR_UNPACKAGER_URL_NOT_PROVIDED='You must provide the un-packager URL as the UNPACKAGER_URL environment variable'
  ERROR_EXCEPTION_RAISED='Exception raised while posting package or parsing answer'
  @@internal_callbacks = {}
  
  def self.call(params, content_type)
    raise ArgumentError.new ERROR_UNPACKAGER_URL_NOT_PROVIDED if UNPACKAGER_URL == ''
    STDERR.puts "UploadPackageService#call: params=#{params}"
    
    tempfile = save_file params['package'][:tempfile]
    curl = Curl::Easy.new(UNPACKAGER_URL)
    curl.multipart_form_post = true
    curl.headers['Accept'] = 'application/json'
    curl.headers['Content-Encoding'] = 'gzip'
    begin
      # params={"package"=>{:filename=>"5gtango-ns-package-example.tgo", :type=>nil, :name=>"package", :tempfile=>#<Tempfile:/tmp/RackMultipart20180523-1-ht5k40.tgo>, :head=>"Content-Disposition: form-data; name=\"package\"; filename=\"5gtango-ns-package-example.tgo\"\r\n"}}
      package = params.fetch('package', {})
      filename = package.fetch(:filename, '')
      curl.http_post(
        Curl::PostField.file('package', tempfile.path, filename),
        Curl::PostField.content('callback_url', INTERNAL_CALLBACK_URL),
        Curl::PostField.content('layer', params.fetch('layer', '')),
        Curl::PostField.content('format', params.fetch('format', '')),
        Curl::PostField.content('skip_store', params.fetch('skip_store', 'false'))
      )
        
      # { "package_process_uuid": "03921bbe-8d9f-4cfc-b6ab-88b58cb8db7e", "status": status, "error_msg": p.error_msg}
      result = JSON.parse(curl.body_str, quirks_mode: true, symbolize_names: true)
      STDERR.puts "UploadPackageService#call: result=#{result}"
    rescue Exception => e
      STDERR.puts e.message  
      STDERR.puts e.backtrace.inspect
      raise Error.new(ERROR_EXCEPTION_RAISED) 
    end
    save_user_callback( result[:package_process_uuid], params['callback_url'])
    result
  end
  
  def self.process_callback(params, url)
    # example: https://gist.github.com/mpeuster/4a302c2667dfa1ed428b3c993534841d
    #"package_id":"471504c1-5a05-41e6-b652-b5d6af7db8ec",
    #"package_location":"http://127.0.0.1:4011/catalogues/api/v2/packages/471504c1-5a05-41e6-b652-b5d6af7db8ec",
    params[:package_location] = "#{url}/api/v3/packages/#{params[:package_id]}"
    STDERR.puts "UploadPackageService#process_callback: params=#{params}"
    result = save_result(params)
    notify_external_systems(params) unless EXTERNAL_CALLBACK_URL == ''
    notify_user(params)
    STDERR.puts "UploadPackageService#process_callback: result=#{result}"
    result
  end
  
  def self.status(process_id)
    # should be {"event_name": "onPackageChangeEvent", "package_id": "string", "package_location": "string", 
    # "package_metadata": "string", "package_process_status": "string", "package_process_uuid": "string"}
    process = db_get(process_id)
    return {} if process == nil
    STDERR.puts "UploadPackageService#status result for #{process_id}=#{process[:result]}"
    return process[:result] unless process[:result].to_s.empty?
    FetchPackagesService.status(process_id)
  end
  
  private
  def self.db_get(key)
    @@internal_callbacks[key.is_a?(Symbol) ? key : key.to_sym]
  end
  def self.db_set(key, value)
    @@internal_callbacks[key.is_a?(Symbol) ? key : key.to_sym] = value
  end
  
  def self.save_result(result)
    process = db_get result[:package_process_uuid]
    return {} if process == nil
    process[:result]= result
    STDERR.puts "UploadPackageService#save_result: result=#{process[:result]}"
    process
  end
  
  def self.notify_external_systems(params)
    begin
      curl = Curl::Easy.http_post( EXTERNAL_CALLBACK_URL, params.to_json) do |request|
        request.headers['Accept'] = request.headers['Content-Type'] = 'application/json'
      end
      STDERR.puts "UploadPackageService#notify_external_systems: params=#{params}"
    rescue Curl::Err::TimeoutError, Curl::Err::ConnectionFailedError, Curl::Err::CurlError, Curl::Err::AccessDeniedError, Curl::Err::TimeoutError, Curl::Err::TimeoutError => e
      STDERR.puts "%s - %s: %s", [Time.now.utc.to_s, self.class.name+'#'+__method__.to_s, "Failled to post to external callback #{EXTERNAL_CALLBACK_URL}"]
    end
  end
  
  def self.notify_user(params)
    process = db_get(params[:package_process_uuid])
    return if process == nil
    user_callback = process[:user_callback]
    STDERR.puts "UploadPackageService#notify_user: user_callback=#{user_callback}"
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
    db_set(uuid, { user_callback: user_callback, result: nil})
  end
  
  def self.random_string
    (0...8).map { (65 + rand(26)).chr }.join
  end
end
