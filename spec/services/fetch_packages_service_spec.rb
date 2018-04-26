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

RSpec.describe FetchPackagesService do
  let(:catalogue_url)  {FetchPackagesService::CATALOGUE_URL+'/packages'}
  let(:package_1_metadata) {{vendor: '5gtango', name: 'whatever', version: '0.0.1'}}
  let(:package_2_metadata) {{vendor: '5gtango', name: 'whatever', version: '0.0.2'}}
  let(:packages_metadata) {[package_1_metadata,package_2_metadata]}
  
  describe '.metadata' do    
    it 'calls the Catalogue with default params' do      
      stub_request(:get, catalogue_url+'?page_number=0&page_size=100').
        to_return(status: 200, body: packages_metadata.to_json, headers: {'content-type' => 'application/json'})
      expect(described_class.metadata({})).to eq([package_1_metadata, package_2_metadata])
    end
    it 'calls the Catalogue with default page_size when only page_number is passed' do      
      stub_request(:get, catalogue_url+'?page_number=1&page_size=100').
        to_return(status: 200, body: [].to_json, headers: {'content-type' => 'application/json'})
      expect(described_class.metadata({page_number: 1})).to eq([])
    end
    it 'calls the Catalogue with default page_number when only page_size is passed' do      
      stub_request(:get, catalogue_url+'?page_number=0&page_size=1').
        to_return(status: 200, body: [package_1_metadata].to_json, headers: {'content-type' => 'application/json'})
      expect(described_class.metadata({page_size: 1})).to eq([package_1_metadata])
    end
  end
end