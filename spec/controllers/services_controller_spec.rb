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

RSpec.describe ServicesController, type: :controller do
  include Rack::Test::Methods
  def app() ServicesController end

  describe 'Accepts services queries' do
    let(:service_1_metadata) {{vendor: '5gtango', name: 'whatever', version: '0.0.1'}}
    let(:service_2_metadata) {{vendor: '5gtango', name: 'whatever', version: '0.0.2'}}
    let(:services_metadata) {[service_1_metadata, service_2_metadata]}
    
    it 'adding default parameters for page size and number' do
      allow(FetchServicesService).to receive(:call).with({}).and_return(services_metadata)
      get '/'
      expect(last_response).to be_ok
      expect(last_response.body).to eq(services_metadata.to_json)
    end
    
    it 'returning not found (404) when an error occurs' do
      allow(FetchServicesService).to receive(:call).with({}).and_return(nil)
      get '/'
      expect(last_response.status).to eq(404)
    end
    
    it 'returning Ok (200) and an empty array when no package is found' do
      allow(FetchServicesService).to receive(:call).with({}).and_return([])
      get '/'
      expect(last_response).to be_ok
      expect(last_response.body).to eq([].to_json)
    end
  end
  describe 'Accepts single package query' do
    let(:uuid) {SecureRandom.uuid}
    let(:service_metadata) { {service_uuid: uuid, nsd: {vendor: '5gtango', name: 'whatever', version: '0.0.1'}}}
    it 'returning Ok (200) and the servive meta-data when the service is found' do
      allow(FetchServicesService).to receive(:call).with({service_uuid: uuid}).and_return(service_metadata)
      get '/'+uuid
      expect(last_response).to be_ok
      expect(last_response.body).to eq(service_metadata.to_json)
    end
  end
end