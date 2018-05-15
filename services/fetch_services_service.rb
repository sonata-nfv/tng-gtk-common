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

class FetchServicesService
  
  # curl http://localhost:4011/catalogues/api/v2
  CATALOGUE_URL = ENV.fetch('CATALOGUE_URL', '')
  NO_CATALOGUE_URL_DEFINED_ERROR='The CATALOGUE_URL ENV variable needs to defined and pointing to the Catalogue where to fetch packages'
  UNPACKAGER_URL= ENV.fetch('UNPACKAGER_URL', '')
  NO_UNPACKAGER_URL_DEFINED_ERROR='The UNPACKAGER_URL ENV variable needs to defined and pointing to the Packager component URL'
  
  def self.call(params)
    if CATALOGUE_URL == ''
      STDERR.puts "%s - %s: %s" % [Time.now.utc.to_s, self.name+'#'+__method__.to_s, NO_CATALOGUE_URL_DEFINED_ERROR]
      return nil 
    end
    begin
      if params.key?(:package_uuid)
        package_uuid = params.delete :package_uuid
        uri = URI.parse(CATALOGUE_URL+'/packages/'+package_uuid)
        # mind that there ccany be more params, so we might need to pass params as well
      else
        uri = URI.parse(CATALOGUE_URL+'/packages')
        uri.query = URI.encode_www_form(sanitize(params))
      end
      STDERR.puts "FetchPackagesService#metadata: querying uri=#{uri}"
      request = Net::HTTP::Get.new(uri)
      request['content-type'] = 'application/json'
      response = Net::HTTP.start(uri.hostname, uri.port) {|http| http.request(request)}
      STDERR.puts "FetchPackagesService#metadata: querying response=#{response}"
      return JSON.parse(response.read_body, quirks_mode: true, symbolize_names: true) if response.is_a?(Net::HTTPSuccess)
    rescue Exception => e
      STDERR.puts "%s - %s: %s" % [Time.now.utc.to_s, self.name+'#'+__method__.to_s, e.message]
    end
    nil
  end
    
  private
  def self.sanitize(params)
    params[:page_number] ||= ENV.fetch('DEFAULT_PAGE_NUMBER', 0)
    params[:page_size]   ||= ENV.fetch('DEFAULT_PAGE_SIZE', 100)
    params
  end
  
end
