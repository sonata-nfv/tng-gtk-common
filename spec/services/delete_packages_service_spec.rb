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

RSpec.describe DeletePackagesService do
  let(:catalogue_url)  {FetchPackagesService::CATALOGUE_URL}
  
  it 'breaks unless CATALOGUE_URL ENV message is defined' do
    expect(described_class.const_defined?(:CATALOGUE_URL)).to be_truthy   
  end
    
  describe '.call' do    
    let(:uuid) {SecureRandom.uuid}
    it 'return 0 for an existing package UUID' do      
      stub_request(:delete, catalogue_url+'/packages/'+uuid).to_return(status: 204, body: '', headers: {})
      expect(described_class.call(uuid)).to eq(0)
    end
    it 'return nil for a non-existing package UUID' do      
      stub_request(:delete, catalogue_url+'/packages/'+uuid).to_return(status: 404, body: '', headers: {})
      expect(described_class.call(uuid)).to eq(nil)
    end
  end
end