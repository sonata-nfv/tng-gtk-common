FROM ruby:2.4.3-slim-stretch
RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential libcurl3 libcurl3-gnutls libcurl4-openssl-dev && \
	  rm -rf /var/lib/apt/lists/*
RUN mkdir -p /app/lib/local-gems
WORKDIR /app
COPY Gemfile /app
RUN bundle install
COPY . /app
EXPOSE 5000
ENV PORT 5000
ENV ROUTES_FILE=sp_routes.yml
ENV UNPACKAGER_URL=http://tng-sdk-package:5099/api/v1/packages
ENV INTERNAL_CALLBACK_URL=http://tng-gtk-common:5000/on-change
ENV EXTERNAL_CALLBACK_URL=http://tng-vnv-lcm:6100/api/v1/packages/on-change
CMD ["bundle", "exec", "rackup", "-p", "5000", "--host", "0.0.0.0"]
