[![Build Status](https://jenkins.sonata-nfv.eu/buildStatus/icon?job=tng-gtk-sp/master)](https://jenkins.sonata-nfv.eu/job/tng-gtk-common/master)[![Join the chat at https://gitter.im/sonata-nfv/Lobby](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/sonata-nfv/Lobby)

<p align="center"><img src="https://github.com/sonata-nfv/tng-api-gtw/wiki/images/sonata-5gtango-logo-500px.png" /></p>

# Common Gatekeeper component for the V&V and Service platforms
This is the **5GTANGO common Gatekeeper component for the Verification&Validation and the Service platforms** repository, which complements the [SP-](https://github.com/sonata-nfv/tng-gtk-sp) and [V&V-specific](https://github.com/sonata-nfv/tng-gtk-vnv) repositories.

Please see [details on the overall 5GTANGO architecture here](https://5gtango.eu/project-outcomes/deliverables/2-uncategorised/31-d2-2-architecture-design.html). The Gatekeeper is the component highlighted in the following picture.

<p align="center"><img src="https://github.com/sonata-nfv/tng-api-gtw/wiki/images/GKs_place_in_5GTANGO_architecture.png" /></p>

## Supported endpoints
Supported endpoints, alphabetically sorted, are described next. These endpoints are internal, only the ones exposed by the [router](https://github.com/sonata-nfv/tng-api-gtw/blob/master/tng-router) in the [Service Platform's](https://github.com/sonata-nfv/tng-api-gtw/blob/master/tng-router/config/sp_routes.yml) and [V&V Platform's](https://github.com/sonata-nfv/tng-api-gtw/blob/master/tng-router/config/vnv_routes.yml) routing files are available from the outside.

**Endpoints**|**Description**
:----|:----
`/`|The root of the API.
`/functions`|[Lists available functions (VNFs) in the Catalogue](https://github.com/sonata-nfv/tng-gtk-common/wiki/functions-querying)
`/packages`|[Manages packages](https://github.com/sonata-nfv/tng-api-gtw/wiki/packages-management) (uploading, downloading, etc.)
`/pings`|[The Gatekeeper's `readiness` and `liveness` endpoint](https://github.com/sonata-nfv/tng-api-gtw/wiki/readiness-liveliness-probe)
`/services`|[Lists available services (NSs) in the Catalogue](https://github.com/sonata-nfv/tng-gtk-common/wiki/services-querying)

## Installing / Getting started

This component is implemented in [ruby](https://www.ruby-lang.org/en/), version **2.4.3**. 

### Installing from code

To have it up and running from code, please do the following:

```shell
$ git clone https://github.com/sonata-nfv/tng-gtk-common.git # Clone this repository
$ cd tng-gtk-common # Go to the newly created folder
$ bundle install # Install dependencies
$ PORT=5000 bundle exec rackup # dev server at http://localhost:5000
```
**Note:** See the [Configuration](#configuration) section below for other environment variables that can be used.

Everything being fine, you'll have a server running on that session, on port `5000`. You can use it by using `curl`, like in:

```shell
$ curl <host name>:5000/
```

### Installing from the Docker container
In case you prefer a `docker` based development, you can run the following commands (`bash` shell):

```shell
$ docker network create tango
$ docker run -d -p 27017:27017 --net=tango --name mongo mongo
$ docker run -d -p 4011:4011 --net=tango --name tng-cat sonatanfv/tng-cat:dev
$ docker run -d -p 5099:5099 --net=tango --name tng-sdk-package sonatanfv/tng-sdk-package:dev
$ docker run -d -p 5000:5000 --net=tango --name tng-gtk-common \
  -e CATALOGUE_URL=http://tng-cat:4011/catalogues/api/v2 \
  -e UNPACKAGER_URL=http://tng-sdk-package:5099/api/v1/packages \
  sonatanfv/tng-gtk-common:dev
```

**Note:** user and password are mere indicative, please choose the apropriate ones for your deployment.

With these commands, you:

1. Create a `docker` network named `tango`;
1. Run the [MongoDB](https://www.mongodb.com/) container within the `tango` network;
1. Run the [Catalogue](https://github.com/sonata-nfv/tng-cat) container within the `tango` network;
1. Run the [SDK Package](https://github.com/sonata-nfv/tng-sdk-package) container within the `tango` network;
1. Run the [V&V/SP-common Gatekeeper](https://github.com/sonata-nfv/tng-gtk-common) container within the `tango` network, with the needed environment variables set to the previously created containers.

## Developing
This section covers all the needs a developer has in order to be able to contribute to this project.

### Built With
We are using the following libraries (also referenced in the [`Gemfile`](https://github.com/sonata-nfv/tng-gtk-sp/Gemfile) file) for development:

* `curb` (`0.9.3`), an HTTP library;
* `faraday` (`0.14.0`), an HTTP library;
* `puma` (`3.11.0`), an application server;
* `rack` (`2.0.4`), a web-server interfacing library, on top of which `sinatra` has been built;
* `rack-uploads` (`0.2.1`), an uploader *middleware* for `sinatra`;
* `rake`(`12.3.0`), a dependencies management tool for ruby, similar to *make*;
* `sinatra` (`2.0.2`), a web framework for implementing efficient ruby APIs;
* `sinatra-contrib` (`2.0.2`), several add-ons to `sinatra`;
* `sinatra-cross_origin` (`0.4.0`), a *middleware* to `sinatra` that helps in managing the [`Cross Origin Resource Sharing (CORS)`](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) problem;

The following *gems* (libraries) are used just for tests:
* `ci_reporter_rspec` (`1.0.0`), a library for helping in generating continuous integration (CI) test reports;
* `rack-test` (`0.8.2`), a helper testing framework for `rack`-based applications;
* `rspec` (`3.7.0`), a testing framework for ruby;
* `rubocop` (`0.52.0`), a library for white box tests; 
* `rubocop-checkstyle_formatter` (`0.4.0`), a helper library for `rubocop`;
* `webmock` (`3.1.1`), which alows *mocking* (i.e., faking) HTTP calls;

These libraries are installed/updated in the developer's machine when running the command (see above):

```shell
$ bundle install
```

### Prerequisites
We usually use [`rbenv`](https://github.com/rbenv/rbenv) as the ruby version manager, but others like [`rvm`](https://rvm.io/) may work as well.

### Setting up Dev
Developing this micro-service is straight-forward with a low amount of necessary steps.

Routes within the micro-service are defined in the [`config.ru`](https://github.com/sonata-nfv/tng-gtk-common/blob/master/config.ru) file, in the root directory. It has two sections:

* The `require` section, where all used libraries must be required (**Note:** `controllers` had to be required explicitly, while `services` do not, due to a bug we have found to happened in some of the environments);
* The `map` section, where this micro-service's routes are mapped to the controller responsible for it.

This new or updated route can then be mapped either into an existing controller or imply writing a new controller. This new or updated controller can use either existing or newly written services to fullfil it's role.

For further details on the micro-service's architecture please check the [documentation](https://github.com/sonata-nfv/tng-gtk-common/wiki/micro-service-architecture).

### Submiting changes
Changes to the repository can be requested using [this repository's issues](https://github.com/sonata-nfv/tng-gtk-common/issues) and [pull requests](https://github.com/sonata-nfv/tng-gtk-common/pulls) mechanisms.

## Versioning

The most up-to-date version is v4. For the versions available, see the [link to tags on this repository](https://github.com/sonata-nfv/tng-gtk-common/releases).

## Configuration
The configuration of the micro-service is done through the following environment variables, defined in the [Dockerfile](https://github.com/sonata-nfv/tng-gtk-common/blob/master/Dockerfile):

* `CATALOGUE_URL`, which defines the [Catalogue](http://github.com/sonata-nfv/tng-cat)'s URL, where packages, services and functions descriptors are fetched from (and also indirectely store when a package is successfuly uploaded);
* `UNPACKAGER_URL`, which defines the [Packager](https://github.com/sonata-nfv/tng-sdk-package)'s URL, where packages are unpackaged and validated, before being stored in the Catalogue;

Optionally, you can also define the following `ENV` variables:

* `UPLOADED_CALLBACK_URL`, which defines the `URL` for the [Packager](https://github.com/sonata-nfv/tng-sdk-package) component to notify this component about the finishing of the upload process, defaults to `http://tng-gtk-common:5000/packages/on-change`;
* `NEW_PACKAGE_CALLBACK_URL`, which defines the `URL` that this component should call, when  it is notified (by the [Packager](https://github.com/sonata-nfv/tng-sdk-package) component) that the package has been on-boarded, e.g.,`http://tng-vnv-lcm:6100/api/v1/packages/on-change`. See details on this component's [Design documentation wiki page](https://github.com/sonata-nfv/tng-gtk-common/wiki/design-documentation);
* `DEFAULT_PAGE_SIZE`, which defines the default number of 'records' that are returned on a single query, for pagination purposes. If absent, a value of `100` is assumed;
* `DEFAULT_PAGE_NUMBER`, which defines the default page to start showing the selected records (beginning at `0`), for pagination purposes. If absent, a value of `0` is assumed;

## Tests
Unit tests are defined for both `controllers` and `services`, in the `/spec` folder. Since we use `rspec` as the test library, we configure tests in the [`spec_helper.rb`](https://github.com/sonata-nfv/tng-gtk-common/blob/master/spec/spec_helper.rb) file, also in the `/spec` folder.

These tests are executed by running the following command:
```shel
$ CATALOGUE_URL=... UNPACKAGER_URL=... bundle exec rspec spec
```

Wider scope (integration and functional) tests involving this micro-service are defined in [`tng-tests`](https://github.com/sonata-nfv/tng-tests).

## Style guide
Our style guide is really simple:

1. We try to follow a [Clean Code](https://www.amazon.com/Clean-Code-Handbook-Software-Craftsmanship/dp/0132350882) philosophy in as much as possible, i.e., classes and methods should do one thing only, have the least number of parameters possible, etc.;
1. we use **two spaces** for identation.

## Api Reference

We have specified this micro-service's API in a [swagger](https://github.com/sonata-nfv/tng-gtk-common/blob/master/doc/swagger.json)-formated file. Please check it there.

## Licensing

This 5GTANGO component is published under Apache 2.0 license. Please see the [LICENSE](https://github.com/sonata-nfv/tng-gtk-common/blob/master/LICENSE) file for more details.

#### Feedback-Channel

* Please use the GitHub issues to report bugs.
* You may use the mailing list [sonata-dev@lists.atosresearch.eu](mailto:sonata-dev@lists.atosresearch.eu)
