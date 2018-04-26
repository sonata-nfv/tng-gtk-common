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

class PackageController < ApplicationController

  INTERNAL_CALLBACK_URL = ENV.fetch('INTERNAL_CALLBACK_URL', '')
  OK_PACKAGE_ACCEPTED="{'package_process_uuid':'%s', 'package_process_status':'%s'}"
  ERROR_PACKAGE_CONTENT_TYPE={error: 'Just accepting multipart package files for now'}
  ERROR_PACKAGE_ACCEPTATION={error: 'Problems accepting package for unpackaging and validation...'}

  settings.logger.info(self.name) {"Started at #{settings.began_at}"}
  
  # Accept packages and pass them to the unpackager/validator component
  post '/?' do
    # RESET = 'reset' unless const_defined?(:RESET)

    halt 400, {}, ERROR_PACKAGE_CONTENT_TYPE.to_json unless request.content_type =~ /^multipart\/form-data/
    
    begin
      ValidatePackageParametersService.call request.params
    rescue ArgumentError => e
      halt 400, {}, 'Package file parameter is missing'
    end
    code, body = UploadPackageService.call( request.params, request.content_type, INTERNAL_CALLBACK_URL)
    case code
    when 200
      halt 200, {}, OK_PACKAGE_ACCEPTED % [body[:package_process_uuid], body[:package_process_status]]
    else
      halt code, {}, ERROR_PACKAGE_ACCEPTATION.to_json
    end
  end
  
  # Callback for the tng-sdk-packager to notify the result of processing
  post '/on-change/?' do
    ERROR_EVENT_CONTENT_TYPE={error: 'Just accepting callbacks in json'}
    ERROR_EVENT_PARAMETER_MISSING={error: 'Event received with no data'}
    OK_CALLBACK_PROCESSED = "Callback for process id %s processed"

    halt 400, {}, ERROR_EVENT_CONTENT_TYPE.to_json unless request.content_type =~ /application\/json/
    begin
      ValidateEventParametersService.call(request.body.read)
    rescue ArgumentError => e
      halt 400, {}, e.message
    end
    UploadPackageService.process_callback(event_data)
    halt 200, {}, OK_CALLBACK_PROCESSED % event_data
  end
  
  get '/status/:process_uuid/?' do
    #ERROR_PROCESS_UUID_NOT_VALID="Process UUID %s not valid"
    #ERROR_NO_STATUS_FOUND="No status found for %s processing id"
    halt 400, {}, {error: "Process UUID #{params[:process_uuid]} not valid"}.to_json unless uuid_valid?(params[:process_uuid])
    result = UploadPackageService.fetch_status(params[:process_uuid])
    halt 404, {}, {error: "No status found for '#{params[:process_uuid]}' processing id"}.to_json if result.to_s.empty? 
    halt 200, {}, result.to_json
  end

  get '/?' do 
    captures=params.delete('captures') if params.key? 'captures'
    result = FetchPackagesService.metadata(params)
    halt 404, {}, {error: "No packages fiting the provided parameters ('#{params}') were found"}.to_json if result.to_s.empty? # covers nil
    #halt 404, {}, {error: "No packages fiting the provided parameters ('#{params}') were found"}.to_json if result.empty? 
    halt 200, {}, result.to_json
  end
  
  get '/:package_uuid?' do 
    halt 501, {}, ['.../api/v3/packages/:package_uuid is not implemented yet']
  end
  
  get '/:package_uuid/file/?' do 
    halt 501, {}, ['.../api/v3/packages/:package_uuid/file is not implemented yet']
  end

  private
  def uuid_valid?(uuid)
    return true if (uuid =~ /[a-f0-9]{8}-([a-f0-9]{4}-){3}[a-f0-9]{12}/) == 0
    false
  end
end
