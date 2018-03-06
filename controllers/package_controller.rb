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
#require_relative '../services/upload_package_service'

class PackageController < ApplicationController

  before { content_type :json}
  CALLBACK_PATH = '/packages/on-change'
  CALLBACK_URL = 'http://tng-gtk-common'+CALLBACK_PATH
  ERROR={status: 400, message: 'Just accepting multipart package file for now'}
  
  # Accept packages and pass them to the unpackager/validator component
  post '/?' do
    halt 400, {}, ERROR.to_json unless request.content_type =~ /^multipart\/form-data/
    
    begin
      ValidatePackageParametersService.call request.params
    rescue ArgumentError => e
      halt 400, {}, 'Package file parameter is missing'
    end
    code, body = UploadPackageService.call( request.params, request.content_type, settings.unpackager_url, CALLBACK_URL)
    case code
    when 200
      halt 200, {}, "Unpackaging and validation is running with process id #{body[:package_process_uuid]}"
    else
      halt code, {}, "Problems accepting package for unpackaging and validation..."
    end
  end
  
  post CALLBACK_PATH+'/?' do
    #, settings.external_callback_url
    # {"event_name": "string", "package_id": "string","package_location": "string"}
    
  end
end
