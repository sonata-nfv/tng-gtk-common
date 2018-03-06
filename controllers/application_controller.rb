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
require 'sinatra/base'
require 'sinatra/config_file'
require 'sinatra/cross_origin'
# require 'sinatra/logger'

class ApplicationController < Sinatra::Base
  register Sinatra::ConfigFile
  register Sinatra::CrossOrigin
  #register Sinatra::Logger

  set :bind, '0.0.0.0'
  set :began_at, Time.now.utc
  set :environment, ENV['RACK_ENV'] || :development
  config_file File.join('..', 'config', 'services.yml')
  #set :logger_level, (settings.logger_level ||= 'debug').to_sym # can be debug, fatal, error, warn, or info
	#enable :logging
  enable :cross_origin
  #$stderr.puts "Settings:\n  #{settings.environment}\n  #{settings.unpackager_url}"
end