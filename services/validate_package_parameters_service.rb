## SONATA - Gatekeeper
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
class ValidatePackageParametersService
  # from here: https://git.cs.upb.de/5gtango/generalInfo/wikis/user-story-t41-1-packaging#unpacking
  def self.call(params)
    # Example params: {"x"=>"1", "y"=>"2", "package"=>{:filename=>"Gemfile", :type=>nil, :name=>"package", :tempfile=>#<Tempfile:/var/folders/7j/8jj6x0ld6pz_rhdvblh9jy3r0000gn/T/RackMultipart20180302-20343-199a5yp>, :head=>"Content-Disposition: form-data; name=\"package\"; filename=\"Gemfile\"\r\n"}}

    # package is mandatory, of type file, no default value: Uploaded package file
    raise ArgumentError.new('Package parameter is mandatory') unless valid_package_param?(params)
    true
    
    # Other fields:
    # callback_url, optional, string, no default value: URL called after unpackaging
    # layer, optional, string, no default value: Layer tag to be unpackaged
    # format, optional, string, default value eu.5gtango: Package format
    # skip_store, optional, string, default value eu.5gtango: if just a test to the Package (no storage) is intended
  end
  
  private
  def self.valid_package_param?(params)
    params.key?('package') && params['package'].key?(:filename) && params['package'].key?(:tempfile)
  end
end