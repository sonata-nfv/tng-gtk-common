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
require 'json'
require 'net/http'
require 'tng/gtk/utils/logger'
require 'tng/gtk/utils/cache'

class DeletePackagesService
  LOGGER=Tng::Gtk::Utils::Logger
  LOGGING_CLASS=self.name
  
  # curl http://localhost:4011/catalogues/api/v2
  CATALOGUE_URL = ENV.fetch('CATALOGUE_URL', '')
  NO_CATALOGUE_URL_DEFINED_ERROR='The CATALOGUE_URL ENV variable needs to defined and pointing to the Catalogue where to fetch packages'
  
  def self.call(package_uuid)
    if CATALOGUE_URL == ''
      LOGGER.error(component:LOGGING_CLASS, operation:'.call', message:NO_CATALOGUE_URL_DEFINED_ERROR)
      return nil 
    end
    
    begin
      uri = URI.parse(CATALOGUE_URL+'/packages/'+package_uuid)
      LOGGER.debug(component:LOGGING_CLASS, operation:'.call', message:"querying uri=#{uri}")
      request = Net::HTTP::Delete.new(uri)
      request['content-type'] = 'application/json'
      response = Net::HTTP.start(uri.hostname, uri.port) {|http| http.request(request)}
      LOGGER.debug(component:LOGGING_CLASS, operation:'.call', message:"querying response=#{response}")
      if response.is_a?(Net::HTTPSuccess)
        Tng::Gtk::Utils::Cache.clear package_uuid
        return 0 
      end
    rescue Exception => e
      LOGGER.error(component:LOGGING_CLASS, operation:'.call', message:e.message)
    end
    nil
  end
end
