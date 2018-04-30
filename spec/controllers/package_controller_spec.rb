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

RSpec.describe PackageController, type: :controller do
  include Rack::Test::Methods
  def app() PackageController end

  describe 'Accepts (POST) uploaded packages' do
    # http://seejohncode.com/2012/04/29/quick-tip-testing-multipart-uploads-with-rspec/
    let(:file_data) { Rack::Test::UploadedFile.new(__FILE__, 'multipart/form-data')}
    let(:dummy_data) { {dummy: 'data'}}
    let (:result) {{ package_process_uuid: "03921bbe-8d9f-4cfc-b6ab-88b58cb8db7e", package_status: 'waiting'}}
  
    context 'when they are multipart and' do
      it 'returning 200 when everything was ok' do
        allow(ValidatePackageParametersService).to receive(:call).and_return(true)
        allow(UploadPackageService).to receive(:call).and_return([200, result])
        post '/', package: file_data
        #expect(last_response).to be_created
        expect(last_response.status).to eq(200)
      end
      it 'returning 400 when something was not ok' do
        allow(UploadPackageService).to receive(:call).and_return([400, result])
        post '/', package: file_data
        expect(last_response.status).to eq(400)
      end
    end
    it 'returning 400 when they are non-multipart packages' do
      post '/', dummy_data, headers: {'Content-Type'=>'application/json'}
      expect(last_response.status).to eq(400)
    end
    it 'returning 400 when upload parameters miss the package parameter' do
      post '/'
      expect(last_response.status).to eq(400)
    end
    it "returning 400 when upload parameters is not 'package'" do
      post '/', no_package: file_data
      expect(last_response.status).to eq(400)
    end
  end
  describe 'Accepts callbacks' do
  end
  describe 'Accepts status queries' do
    let(:possible_status) { ["waiting", "running", "failed", "success"]}
    let(:valid_processing_uuid) {SecureRandom.uuid}
    let(:status_message) { {package_process_uuid: valid_processing_uuid, status: "waiting", error_msg: "Whatever"}}
    let(:invalid_processing_uuid) {'abc123'}
    let(:unknown_processing_uuid) {SecureRandom.uuid}
    it "rejecting (400) those with an invalid UUDI" do
      get '/status/'+invalid_processing_uuid
      expect(last_response.status).to eq(400)
    end
    it "rejecting (404) an unknow processing UUID" do
      allow(UploadPackageService).to receive(:fetch_status).with(unknown_processing_uuid).and_return(nil)
      get '/status/'+unknown_processing_uuid
      expect(last_response.status).to eq(404)
    end
    it "accepting (200) valid requests and returning expected data" do
      allow(UploadPackageService).to receive(:fetch_status).with(valid_processing_uuid).and_return(status_message)
      get '/status/'+valid_processing_uuid
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq(status_message.to_json)
    end
  end
  describe 'Accepts packages queries' do
    let(:package_1_metadata) {{vendor: '5gtango', name: 'whatever', version: '0.0.1'}}
    let(:package_2_metadata) {{vendor: '5gtango', name: 'whatever', version: '0.0.2'}}
    
    it 'adding default parameters for page size and number' do
      allow(FetchPackagesService).to receive(:metadata).with({}).and_return([package_1_metadata, package_2_metadata])
      get '/'
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq([package_1_metadata, package_2_metadata].to_json)
    end
    
    it 'returning not found (404) when an error occurs' do
      allow(FetchPackagesService).to receive(:metadata).with({}).and_return(nil)
      get '/'
      expect(last_response.status).to eq(404)
    end
    
    it 'returning Ok (200) and an empty array when no package is found' do
      allow(FetchPackagesService).to receive(:metadata).with({}).and_return([])
      get '/'
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq([].to_json)
    end
  end
  describe 'Accepts single package query' do
    let(:uuid) {SecureRandom.uuid}
    let(:package_metadata) { {package_uuid: uuid, pd: {vendor: '5gtango', name: 'whatever', version: '0.0.1'}}}
    it 'returning Ok (200) and the package meta-data when package is found' do
      allow(FetchPackagesService).to receive(:metadata).with({'package_uuid'=> uuid}).and_return(package_metadata)
      get '/'+uuid
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq(package_metadata.to_json)
    end
  end
  describe 'Accepts single package download query' do
    let(:package_uuid) {SecureRandom.uuid}
    let(:package_file_uuid) {SecureRandom.uuid}
    let(:package_file_name) {'whatever_name.tgo'}
    let(:package_metadata) { {package_uuid: uuid, son_package_uuid: package_file_uuid, grid_fs_name: package_file_name, pd: {vendor: '5gtango', name: 'whatever', version: '0.0.1'}}}
    it 'returning Ok (200) and the package file when package is found' do
      allow(FetchPackagesService).to receive(:package_file).with({'package_uuid'=> package_uuid}).and_return(package_file_name)
      get '/'+package_uuid+'/package-file'
      expect(last_response.status).to eq(200)
      #expect(last_response.body).to eq(package_metadata.to_json)
      #result = get ....

      #result.body.should eq IO.binread(path_to_file)

      
      #expect(send_file).to have_been_called
    end
  end
end