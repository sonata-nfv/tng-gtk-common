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
# encoding: utf-8
require_relative '../spec_helper'

RSpec.describe PackageController, type: :controller do
  include Rack::Test::Methods
  def app() PackageController end

  describe 'Accepts (POST) uploaded packages' do
    # http://seejohncode.com/2012/04/29/quick-tip-testing-multipart-uploads-with-rspec/
    let(:file_data) { Rack::Test::UploadedFile.new(__FILE__, 'multipart/form-data')}
    let(:dummy_data) { {dummy: 'data'}}
    let (:result) {{ 'package_process_uuid'=> "03921bbe-8d9f-4cfc-b6ab-88b58cb8db7e"}}
  
    context 'when they are multipart and' do
      it 'returning 200 when everything was ok' do
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
      post '/', no_package: file_data
      expect(last_response).to be_bad_request
    end
  end
  describe 'Accepts callbacks' do
  end
end