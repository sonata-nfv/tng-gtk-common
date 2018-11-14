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
FROM ruby:2.4.3-slim-stretch
RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential libcurl3 libcurl3-gnutls libcurl4-openssl-dev git && \
	  rm -rf /var/lib/apt/lists/*
RUN mkdir -p /app/lib/local-gems
WORKDIR /app
COPY Gemfile /app
RUN bundle install
COPY . /app
EXPOSE 5000
ENV PORT 5000
#ENV ROUTES_FILE=sp_routes.yml
ENV UNPACKAGER_URL=http://tng-sdk-package:5099/api/v1/packages
ENV CATALOGUE_URL=http://tng-cat:4011/catalogues/api/v2
ENV INTERNAL_CALLBACK_URL=http://tng-gtk-common:5000/packages/on-change
ENV REDIS_URL=redis://son-redis:6379
# To be defined only for the VnV deployment: http://tng-vnv-lcm:6100/api/v1/packages/on-change
ENV EXTERNAL_CALLBACK_URL=
CMD ["bundle", "exec", "rackup", "-p", "5000", "--host", "0.0.0.0"]
