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
require_relative '../spec_helper'

RSpec.describe UploadPackageService do
  let(:user_callback_url)  {'http://example.com/user'}
  let(:external_callback_url) { 'http://example.com/external'}
  let(:unpackager_url) {'http://example.com/unpackager'}

  describe '.call' do
    let (:result) {{ package_process_uuid: "03921bbe-8d9f-4cfc-b6ab-88b58cb8db7e", status: "waiting", error_msg: "None, for now"}}
    let(:internal_callback_url)  {'http://example.com/internal'}
    let(:content_type) {'multipart/form-data'}
    let(:file_data) { Rack::Test::UploadedFile.new(__FILE__, content_type)}
    let(:params) { {'callback_url'=> user_callback_url, 'layer'=> 'xyz', 'format'=>''}.merge!({
      "package"=>{
        filename: __FILE__, 
        type: nil, 
        name: "package", 
        tempfile: file_data,
        head: "Content-Disposition: form-data; name=\"package\"; filename=\"Gemfile\"\r\n"
    }})}
    
    it 'calls the unpackager' do
      #allow(ENV).to receive(:[]).with("TEMP")
      #allow(ENV).to receive(:[]).with("TMP")
      #allow(ENV).to receive(:[]).with("TMPDIR")
      #allow(ENV).to receive(:[]).with("UNPACKAGER_URL").and_return(unpackager_url)
      stub_request(:post, unpackager_url).
        #with(body: "package=%2Ftmp%2FUIYUYTZT20180306-49778-fcognf&callback_url=http%3A%2F%2Fexample.com%2Finternal&layer=xyz&format=").
        to_return(status: 200, body: result.to_json, headers: {})
      expect(UploadPackageService.call(params, content_type, internal_callback_url)).to eq([200, result])
    end
  end
  describe '.process_callback' do
    let(:event_data) { {event_name: "evt", package_id: "123", package_location: "xyz", package_process_uuid: "abc"}}
    before(:each) {
      WebMock.stub_request(:post, external_callback_url).
        with(body: event_data.to_json, headers: {'Accept'=>'application/json', 'Content-Type'=>'application/json'}).
        to_return(status: 200, body: "", headers: {})
      WebMock.stub_request(:post, user_callback_url).
        with(body: event_data.to_json, headers: {'Accept'=>'application/json', 'Content-Type'=>'application/json'}).
        to_return(status: 200, body: "", headers: {})
      allow(ENV).to receive(:[]).with("UNPACKAGER_URL").and_return(unpackager_url)
      allow(UploadPackageService).to receive(:save_result)
      allow(UploadPackageService).to receive(:notify_external_systems)
      allow(UploadPackageService).to receive(:notify_user)
    }
    it 'calls the external callback' do
      UploadPackageService.class_variable_set :@@internal_callbacks, {abc: { user_callback: user_callback_url, result: event_data}}
      expect{UploadPackageService.process_callback(event_data)}.not_to raise_error
    end
    it 'calls the user callback (if exists)' do
      UploadPackageService.class_variable_set :@@internal_callbacks, {'abc'.to_sym => { user_callback: user_callback_url, result: event_data}}
      expect{UploadPackageService.process_callback(event_data)}.not_to raise_error
    end
    it 'does not call the user callback when it does not exist' do
      UploadPackageService.class_variable_set :@@internal_callbacks, {'abc'.to_sym => { user_callback: user_callback_url, result: event_data}}
      expect{UploadPackageService.process_callback(event_data)}.not_to raise_error
    end
    #resp = OpenStruct.new(header_str: "HTTP/1.1 200 OK\nRecord-Count: 1", body: token.to_json)            
    #allow(Curl).to receive(:post).with(login_url, '{}').and_return(resp)
  end
end