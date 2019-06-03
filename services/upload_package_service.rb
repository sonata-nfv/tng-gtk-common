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
require 'tng/gtk/utils/logger'

class UploadPackageService
  @@began_at = Time.now.utc
  LOGGER=Tng::Gtk::Utils::Logger
  LOGGED_COMPONENT=self.name
  LOGGER.info(component:LOGGED_COMPONENT, operation:'initializing', start_stop: 'START', message:"Started at #{@@began_at}")
  
  class << self
    attr_accessor :internal_callbacks
  end
  
  UPLOADED_CALLBACK_URL = ENV.fetch('UPLOADED_CALLBACK_URL', 'http://tng-gtk-common:5000/packages/on-change')
  NEW_PACKAGE_CALLBACK_URL = ENV.fetch('NEW_PACKAGE_CALLBACK_URL', '')
  UNPACKAGER_URL= ENV.fetch('UNPACKAGER_URL', '')
  ERROR_UNPACKAGER_URL_NOT_PROVIDED='You must provide the un-packager URL as the UNPACKAGER_URL environment variable'
  @@internal_callbacks = {}
  LOGGER.error(component:LOGGED_COMPONENT, operation:'initializing', message:ERROR_UNPACKAGER_URL_NOT_PROVIDED) if UNPACKAGER_URL == ''
  RECOMMENDER_URL = ENV.fetch('RECOMMENDER_URL', '')
  
  def self.call(params, user_name)
    msg='.'+__method__.to_s
    LOGGER.debug(component:LOGGED_COMPONENT, operation:msg, message:"params=#{params}")
    
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
        Curl::PostField.content('callback_url', UPLOADED_CALLBACK_URL),
        Curl::PostField.content('layer', params.fetch('layer', '')),
        Curl::PostField.content('format', params.fetch('format', '')),
        Curl::PostField.content('skip_store', params.fetch('skip_store', 'false')),
        Curl::PostField.content('username', user_name)
      )
        
      # { "package_process_uuid": "03921bbe-8d9f-4cfc-b6ab-88b58cb8db7e", "status": status, "error_msg": p.error_msg}
      result = JSON.parse(curl.body_str, quirks_mode: true, symbolize_names: true)
      LOGGER.debug(component:LOGGED_COMPONENT, operation:msg, message:"result=#{result}")
    rescue Exception => e
      LOGGER.error(component:LOGGED_COMPONENT, operation:msg, message:"#{e.message}: #{e.backtrace.join("\n\t")}")
      raise "Exception raised while posting package or parsing answer: #{e.message}: #{e.backtrace.join("\n\t")}"
    end
    callbacks = {}
    callbacks[:client] = params['callback_url'] if params.key?('callback_url')
    callbacks[:recommender] = RECOMMENDER_URL unless RECOMMENDER_URL == ''
    callbacks[:planner] = NEW_PACKAGE_CALLBACK_URL unless NEW_PACKAGE_CALLBACK_URL == ''
    save_callbacks( result[:package_process_uuid], callbacks) if result.key? :package_process_uuid
    result
  end
  
  def self.process_callback(params, url)
    msg='.'+__method__.to_s
    LOGGER.debug(component:LOGGED_COMPONENT, operation:msg, message:"params=#{params}")
    params[:package_location] = "#{url}/api/v3/packages/#{params[:package_id]}"
    result = save_result(params)
    notify_callbacks(params)
    LOGGER.debug(component:LOGGED_COMPONENT, operation:msg, message:"result=#{result}")
    result
  end
  
  def self.status(process_id)
    msg = '.'+__method__.to_s

    LOGGER.debug(component:LOGGED_COMPONENT, operation:msg, message:"process_id=#{process_id}")
    process = db_get(process_id)
    if process == nil
      LOGGER.error(component:LOGGED_COMPONENT, operation:msg, message:"process is nil")
      return {} 
    end
    LOGGER.debug(component:LOGGED_COMPONENT, operation:msg, message:"result for #{process_id}=#{process[:result]}")
    unless process[:result].to_s.empty?
      return process[:result] 
    end
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
    LOGGER.debug(component:LOGGED_COMPONENT, operation:'.'+__method__.to_s, message:"result=#{process[:result]}")
    process
  end
  
  def self.notify_callbacks(params)
    process = db_get(params[:package_process_uuid])
    return if process == nil
    begin
      if (process[:callbacks].key?(:user) && process[:callbacks][:user] != '')
        Curl::Easy.http_post( process[:callbacks][:user], params.to_json) { |http| http.headers['Accept'] = http.headers['Content-Type'] = 'application/json'}
      end
      if (process[:callbacks].key?(:planner) && process[:callbacks][:planner] != '')
        Curl::Easy.http_post( process[:callbacks][:planner], params.to_json) { |http| http.headers['Accept'] = http.headers['Content-Type'] = 'application/json'}
      end
      if (process[:callbacks].key?(:recommender) && process[:callbacks][:recommender] != '' && params.key?(:package_id) && params[:package_id] != '')
        Curl::Easy.http_post( process[:callbacks][:recommender]+'/'+params[:package_id], '') { |http| http.headers['Accept'] = http.headers['Content-Type'] = 'application/json'}
      end
    rescue Curl::Err::TimeoutError, Curl::Err::ConnectionFailedError, Curl::Err::HostResolutionError => e
      LOGGER.error(component:LOGGED_COMPONENT, operation:'.'+__method__.to_s, message:"Failled to post to one of the callbacks #{process[:callbacks]}")
    end
  end

  def self.save_file(io)
    tempfile = Tempfile.new(random_string, '/tmp')
    io.rewind
    tempfile.write io.read
    tempfile.flush
    io.rewind
    tempfile
  end
  
  def self.save_callbacks(uuid, callbacks)
    db_set(uuid, { callbacks: callbacks, result: nil})
  end
  
  def self.random_string
    (0...8).map { (65 + rand(26)).chr }.join
  end
  LOGGER.info(component:LOGGED_COMPONENT, operation:'initializing', start_stop: 'STOP', message:"Ending at #{Time.now.utc}", time_elapsed: Time.now.utc - @@began_at)
end
