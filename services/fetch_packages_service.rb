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
require 'fileutils'
require 'securerandom'

class FetchPackagesService
  
  # curl http://localhost:4011/catalogues/api/v2
  CATALOGUE_URL = ENV.fetch('CATALOGUE_URL', '')
  NO_CATALOGUE_URL_DEFINED_ERROR='The CATALOGUE_URL ENV variable needs to defined and pointing to the Catalogue where to fetch packages'
  UNPACKAGER_URL= ENV.fetch('UNPACKAGER_URL', '')
  NO_UNPACKAGER_URL_DEFINED_ERROR='The UNPACKAGER_URL ENV variable needs to defined and pointing to the Packager component URL'
  
  def self.status(process_id)
    # should be {"event_name": "onPackageChangeEvent", "package_id": "string", "package_location": "string", 
    # "package_metadata": "string", "package_process_status": "string", "package_process_uuid": "string"}
    if UNPACKAGER_URL == ''
      STDERR.puts "%s - %s: %s" % [Time.now.utc.to_s, self.name+'#'+__method__.to_s, NO_CATALOGUE_URL_DEFINED_ERROR]
      return nil 
    end
    begin
      uri = URI.parse(UNPACKAGER_URL+'/status/'+process_id)
      request = Net::HTTP::Get.new(uri)
      request['content-type'] = 'application/json'
      response = Net::HTTP.start(uri.hostname, uri.port) {|http| http.request(request)}
      return JSON.parse(response.read_body, quirks_mode: true, symbolize_names: true) if response.is_a?(Net::HTTPSuccess)
    rescue Exception => e
      STDERR.puts "%s - %s: %s" % [Time.now.utc.to_s, self.name+'#'+__method__.to_s, e.message]
    end
    nil
  end

  def self.metadata(params)
    msg=self.name+'#'+__method__.to_s
    if CATALOGUE_URL == ''
      STDERR.puts "%s - %s: %s" % [Time.now.utc.to_s, msg, NO_CATALOGUE_URL_DEFINED_ERROR]
      return nil 
    end
    STDERR.puts "#{msg}: params=#{params}"
    begin
      if params.key?(:package_uuid)
        package_uuid = params.delete :package_uuid
        uri = URI.parse(CATALOGUE_URL+'/packages/'+package_uuid)
        # mind that there ccany be more params, so we might need to pass params as well
      else
        uri = URI.parse(CATALOGUE_URL+'/packages')
        uri.query = URI.encode_www_form(sanitize(params))
      end
      #STDERR.puts "#{msg}: querying uri=#{uri}"
      request = Net::HTTP::Get.new(uri)
      request['content-type'] = 'application/json'
      response = Net::HTTP.start(uri.hostname, uri.port) {|http| http.request(request)}
      #STDERR.puts "#{msg}: querying response=#{response}"
      return JSON.parse(response.read_body, quirks_mode: true, symbolize_names: true) if response.is_a?(Net::HTTPSuccess)
    rescue Exception => e
      STDERR.puts "%s - %s: %s" % [Time.now.utc.to_s, msg, e.message]
    end
    nil
  end
    
  def self.package_file(params)
    msg=self.name+'#'+__method__.to_s
    if CATALOGUE_URL == ''
      STDERR.puts "%s - %s: %s" % [Time.now.utc.to_s, msg, NO_CATALOGUE_URL_DEFINED_ERROR]
      return nil 
    end
    STDERR.puts "#{msg}: params=#{params}"
    begin
      package_metadata = metadata(package_uuid: params[:package_uuid])
      return nil if package_metadata.to_s.empty?
      STDERR.puts "#{msg}: package_metadata=#{package_metadata}"
      pd = package_metadata.fetch(:pd, {})
      if pd == {}
        STDERR.puts "%s - %s: %s" % [Time.now.utc.to_s, msg, "Package descriptor not set for package '#{params[:package_uuid]}'"]
        return nil
      end
      STDERR.puts "#{msg}: pd=#{pd}"
      package_file_uuid = pd.fetch(:package_file_uuid, '')
      STDERR.puts "#{msg}: package_file_uuid=#{package_file_uuid}"
      if package_file_uuid == ''
        STDERR.puts "%s - %s: %s" % [Time.now.utc.to_s, msg, "Package file UUID not set for package '#{params[:package_uuid]}'"]
        return nil
      end
      package_file_name = pd.fetch(:package_file_name, '')
      STDERR.puts "#{msg}: package_file_name=#{package_file_name}"
      if package_file_name == ''
        STDERR.puts "%s - %s: %s" % [Time.now.utc.to_s, msg, "Package file name not set for package '#{params[:package_uuid]}'"]
        return nil
      end
      download_and_save_file(CATALOGUE_URL+'/tgo-packages/'+package_file_uuid, package_file_name, 'application/zip')
      return package_file_name
    rescue Exception => e
      STDERR.puts "%s - %s: %s" % [Time.now.utc.to_s, msg, e.message]
    end
    nil
  end

  def self.file_by_uuid(params)
    msg=self.name+'#'+__method__.to_s
    if CATALOGUE_URL == ''
      STDERR.puts "%s - %s: %s" % [Time.now.utc.to_s, msg, NO_CATALOGUE_URL_DEFINED_ERROR]
      return [nil, nil]
    end
    STDERR.puts "#{msg}: params=#{params}"
    begin
      package_metadata = metadata(package_uuid: params[:package_uuid])
      STDERR.puts "#{msg}: package_metadata=#{package_metadata}"
      return [nil, nil] if package_metadata.to_s.empty?
      pd = package_metadata.fetch(:pd, {})
      if pd == {}
        STDERR.puts "%s - %s: %s" % [Time.now.utc.to_s, msg, "Package descriptor not set for package '#{params[:package_uuid]}'"]
        return [nil, nil]
      end
      package_content = pd.fetch(:package_content, [])
      if package_content == []
        STDERR.puts "%s - %s: %s" % [Time.now.utc.to_s, msg, "Package package content not set for package '#{params[:package_uuid]}'"]
        return [nil, nil]
      end
      found_file = package_content.detect {|file| file[:uuid] == params[:file_uuid] }
      STDERR.puts "#{msg}: found_file=#{found_file}"
      if found_file.to_s.empty?
        STDERR.puts "%s - %s: %s" % [Time.now.utc.to_s, msg, "Package file UUID '#{params[:file_uuid]}' not found for package '#{params[:package_uuid]}'"]
        return [nil, nil]
      end
      file_name = found_file[:source].split('/').last
      body, headers = download_file(CATALOGUE_URL+'/files/'+found_file[:uuid], file_name) 
      STDERR.puts "#{msg}: body size #{body.bytesize}"
      STDERR.puts "#{msg}: headers  #{headers}"
      return [body, headers]
    rescue Exception => e
      STDERR.puts "%s - %s: %s" % [Time.now.utc.to_s, msg, e.message]
    end
    [nil, nil]
  end
  
  private
  def self.sanitize(params)
    params[:page_number] ||= ENV.fetch('DEFAULT_PAGE_NUMBER', 0)
    params[:page_size]   ||= ENV.fetch('DEFAULT_PAGE_SIZE', 100)
    params
  end
  
  def self.random_string
    (0...8).map { (65 + rand(26)).chr }.join
  end
  
  def self.download_file(file_url, file_name)
    #curl -H "Content-Type:application/zip" http://localhost:4011/api/catalogues/v2/tgo-packages/{id}
    msg=self.name+'#'+__method__.to_s
    body = ''
    headers ={}
    uri = URI.parse(file_url)
    request = Net::HTTP::Get.new(uri)
    request['content-type'] = 'application/octet-stream'
    request['content-disposition'] = 'attachment; filename='+file_name
    Net::HTTP.start(uri.hostname, uri.port) do |http| 
      request2 = Net::HTTP::Get.new uri

      http.request request2 do |response|
        body = response.read_body
        headers = response.to_hash
        STDERR.puts "#{msg}: headers = #{headers} "
        STDERR.puts "#{msg}: body size is #{body.bytesize}"
      end
    end
    [body, headers]
  end

  def self.download_and_save_file(file_url, file_name, content_type)
    #curl -H "Content-Type:application/zip" http://localhost:4011/api/catalogues/v2/tgo-packages/{id}
    uri = URI.parse(file_url)
    request = Net::HTTP::Get.new(uri)
    request['content-type'] = content_type
    request['content-disposition'] = 'attachment; filename='+file_name
    Net::HTTP.start(uri.hostname, uri.port) do |http| 
      request2 = Net::HTTP::Get.new uri

      http.request request2 do |response|
        open('/tmp/'+file_name, 'wb') do |file|
          file.write(response.read_body)
        end
        STDERR.puts "Content-length = #{response['content-length']} "
        STDERR.puts "File '/tmp/#{file_name} size is #{File.size('/tmp/'+file_name)}"
      end
    end
    STDERR.puts "File '/tmp/#{file_name} exists #{File.exist?('/tmp/'+file_name)}"
  end
end
