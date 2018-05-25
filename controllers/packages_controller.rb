## SONATA - Gatekeeper
##
## Copyright (c) 2015 SONATA-NFV [, ANY ADDITIONAL AFFILIATION]
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
## Neither the name of the SONATA-NFV [, ANY ADDITIONAL AFFILIATION]
## nor the names of its contributors may be used to endorse or promote 
## products derived from this software without specific prior written 
## permission.
## 
## This work has been performed in the framework of the SONATA project,
## funded by the European Commission under Grant number 671517 through 
## the Horizon 2020 and 5G-PPP programmes. The authors would like to 
## acknowledge the contributions of their colleagues of the SONATA 
## partner consortium (www.sonata-nfv.eu).
# frozen_string_literal: true
# encoding: utf-8
require 'sinatra'
require 'json'
require 'logger'
require 'securerandom'
#require_relative '../services/upload_package_service'

class PackagesController < ApplicationController

  ERROR_PACKAGE_NOT_FOUND="No package with UUID '%s' was found"
  ERROR_PACKAGE_FILE_NOT_FOUND="No package file for package UUID '%s' was found"
  ERROR_PACKAGE_FILE_PARAMETER_MISSING={error: 'Package file name parameter is missing'}
  ERROR_PACKAGE_CONTENT_TYPE={error: 'Just accepting multipart package files for now'}
  ERROR_PACKAGE_ACCEPTATION={error: 'Problems accepting package for unpackaging and validation...'}
  ERROR_EVENT_CONTENT_TYPE='Just accepting callbacks in json, received %s'
  ERROR_EVENT_PARAMETER_MISSING={error: 'Event received with no data'}
  ERROR_PROCESS_UUID_NOT_VALID="Process UUID %s not valid"
  ERROR_NO_STATUS_FOUND="No status found for %s processing id"

  settings.logger.info(self.name) {"Started at #{settings.began_at}"}
  before { content_type :json}
  
  # Accept packages and pass them to the unpackager/validator component
  post '/?' do
    halt 400, {'content-type'=>'application/json'}, ERROR_PACKAGE_CONTENT_TYPE.to_json unless request.content_type =~ /^multipart\/form-data/
    
    begin
      ValidatePackageParametersService.call request.params
      body = UploadPackageService.call( request.params, request.content_type)
      halt 200, {'content-type'=>'application/json'}, body.to_json
    rescue ArgumentError => e
      halt 400, {'content-type'=>'application/json'}, {error: e.message}.to_json
    end
    halt code, {'content-type'=>'application/json'}, ERROR_PACKAGE_ACCEPTATION.to_json
  end
  
  # Callback for the tng-sdk-packager to notify the result of processing
  post '/on-change/?' do
    STDERR.puts "PackagesController POST on-change: request.content_type=#{request.content_type}"
    #halt 400, {}, {error: ERROR_EVENT_CONTENT_TYPE % request.content_type}.to_json unless request.content_type =~ /application\/json/
    begin
      event_data = ValidateEventParametersService.call(request.body.read)
      result = UploadPackageService.process_callback(event_data)
      halt 200, {}, result.to_json unless result == {}
      halt 404, {}, {error: "Package processing UUID not found in event #{event_data}"}.to_json
    rescue ArgumentError => e
      halt 400, {}, {error: e.message}.to_json
    end
  end
  
  get '/status/:process_uuid/?' do
    halt 400, {}, {error: ERROR_PROCESS_UUID_NOT_VALID % params[:process_uuid]}.to_json unless uuid_valid?(params[:process_uuid])
    result = UploadPackageService.status(params[:process_uuid])
    halt 404, {}, {error: ERROR_NO_STATUS_FOUND % params[:process_uuid]}.to_json if result.to_s.empty? 
    halt 200, {}, result.to_json
  end

  get '/?' do 
    captures=params.delete('captures') if params.key? 'captures'
    result = FetchPackagesService.metadata(symbolized_hash(params))
    halt 404, {}, {error: "No packages fiting the provided parameters ('#{params}') were found"}.to_json if result.to_s.empty? # covers nil
    halt 200, {}, result.to_json
  end
  
  get '/:package_uuid/?' do 
    captures=params.delete('captures') if params.key? 'captures'
    result = FetchPackagesService.metadata(symbolized_hash(params))
    halt 404, {}, {error: ERROR_PACKAGE_NOT_FOUND % params[:package_uuid]}.to_json if result.to_s.empty? # covers nil
    halt 200, {}, result.to_json
  end
  
  get '/:package_uuid/package-file/?' do 
    captures=params.delete('captures') if params.key? 'captures'
    body, headers = FetchPackagesService.package_file(symbolized_hash(params))
    halt 404, {}, {error: ERROR_PACKAGE_FILE_NOT_FOUND % params[:package_uuid]}.to_json if file_name.to_s.empty? # covers nil
    halt 200, headers, body
  end

  get '/:package_uuid/files/:file_uuid?' do 
    captures=params.delete('captures') if params.key? 'captures'
    body, headers = FetchPackagesService.file_by_uuid(symbolized_hash(params))
    halt 404, {}, {error: ERROR_PACKAGE_FILE_NOT_FOUND % params[:package_uuid]}.to_json if body.to_s.empty? # covers nil
    halt 200, headers, body
  end

  delete '/:package_uuid/?' do 
    #captures=params.delete('captures') if params.key? 'captures'
    result = DeletePackagesService.call(params[:package_uuid])
    halt 404, {}, {error: ERROR_PACKAGE_NOT_FOUND % params[:package_uuid]}.to_json if result.to_s.empty? # covers nil
    halt 204, {}, {}
  end
  
  options '/?' do
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'GET,DELETE'      
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With'
    halt 200
  end
  
  private
  def uuid_valid?(uuid)
    return true if (uuid =~ /[a-f0-9]{8}-([a-f0-9]{4}-){3}[a-f0-9]{12}/) == 0
    false
  end
  
  def symbolized_hash(hash)
    Hash[hash.map{|(k,v)| [k.to_sym,v]}]
  end
end
