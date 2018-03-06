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
require 'securerandom'
require 'tempfile'
require 'fileutils'
require 'curb'
require 'net/http/post/multipart'

class UploadPackageService
  
  @@internal_calbacks = {}
  
  def self.call(params, content_type, unpackager_url, internal_callback_url)
    save_user_callback(params['callback_url'])
    tempfile = save_file params['package'][:tempfile]
    curl = Curl::Easy.new(unpackager_url)
    curl.multipart_form_post = true
    curl.http_post(
      Curl::PostField.file('package', tempfile.path),
      Curl::PostField.content('callback_url', internal_callback_url),
      Curl::PostField.content('layer', params['layer']),
      Curl::PostField.content('format', params['format'])
    )
    # { "package_process_uuid": "03921bbe-8d9f-4cfc-b6ab-88b58cb8db7e"}
    [curl.response_code.to_i, JSON.parse(curl.body_str, quirks_mode: true)]
  end
  
  private
  def self.save_file(io)
    tempfile = Tempfile.new(random_string, '/tmp')
    io.rewind
    tempfile.write io.read
    io.rewind
    tempfile
  end
  
  def self.save_user_callback(user_callback)
    key = SecureRandom.uuid
    @@internal_calbacks[key.to_sym] = user_callback
    # callback URL is fixed, key will be used later
    # /api/v1/packages/on-change
  end
  
  def self.swap_to_user(internal_uuid)
    @@internal_calbacks[internal_uuid]
  end

  def self.random_string
    (0...8).map { (65 + rand(26)).chr }.join
  end
end
=begin
    url = URI.parse(unpackager_url)
    post_req = Net::HTTP::Post.new(url)
    post_stream = File.open(params[:package][:tempfile].path, 'rb')
    post_req.content_length = post_stream.size
    post_req.content_type = content_type
    post_req.body_stream = post_stream
    resp = Net::HTTP.new(url.host, url.port).start {|http| http.request(post_req) }
    [resp.code, {'Content-Type'=>'application/json'}, resp.body]
=end