[![Build Status](https://jenkins.sonata-nfv.eu/buildStatus/icon?job=tng-gtk-sp/master)](https://jenkins.sonata-nfv.eu/job/tng-gtk-common/master)
[![Join the chat at https://gitter.im/5gtango/tango-schema](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/5gtango/tango-schema)

<p align="center"><img src="https://github.com/sonata-nfv/tng-api-gtw/wiki/images/sonata-5gtango-logo-500px.png" /></p>

# Gatekeeper common component for the V&V and Service platforms
This is the **5GTANGO Gatekeeper common component for the Verification&Validation and the Service platforms** repository, which complements the [SP-](https://github.com/sonata-nfv/tng-gtk-sp) and [V&V-specific](https://github.com/sonata-nfv/tng-gtk-vnv) repositories.

Please see [details on the overall 5GTANGO architecture here](https://5gtango.eu/project-outcomes/deliverables/2-uncategorised/31-d2-2-architecture-design.html).

## Installing / Getting started

This component is implemented in [ruby](https://www.ruby-lang.org/en/) (we're using version **2.4.3**). 

### Installing from code

To have it up and running from code, please do the following:

```shell
$ git clone https://github.com/sonata-nfv/tng-gtk-common.git # Clone this repository
$ cd tng-gtk-sp # Go to the newly created folder
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
$ docker run -d -p 5099:5099 --net=tango --name tng-sdk-package sonatanfv/tng-sdk-package
$ docker run -d -p 4011:4011 --net=tango --name tng-cat sonatanfv/tng-cat:dev
$ docker run -d -p 5000:5000 --net=tango --name tng-gtk-common \
  -e CATALOGUE_URL=http://tng-cat:4011/catalogues/api/v2 \
  -e 
  sonatanfv/tng-gtk-common:dev
```

**Note:** user and password are mere indicative, please choose the apropriate ones for your deployment.

With these commands, you:

1. Create a `docker` network named `tango`;
1. Run the [MongoDB](https://www.mongodb.com/) container within the `tango` network;
1. Run the [PostgreSQL](https://www.postgresql.org/) container within the `tango` network;
1. Run the [RabbitMQ](https://www.rabbitmq.com/) container within the `tango` network;
1. Run the [Catalogue](https://github.com/sonata-nfv/tng-cat) container within the `tango` network;
1. Run the [Repository](https://github.com/sonata-nfv/tng-rep) container within the `tango` network;
1. Run the [SP-specific Gatekeeper](https://github.com/sonata-nfv/tng-gtk-sp) container within the `tango` network, with the needed environment variables set to the previously created containers.

## Developing
This section covers all the needs a developer has in order to be able to contribute to this project.

### Built With
We are using the following libraries (also referenced in the [`Gemfile`](https://github.com/sonata-nfv/tng-gtk-sp/Gemfile) file) for development:

* `activerecord` (`5.2`), the *Object-Relational Mapper (ORM)*;
* `bunny` (`2.8.0`), the adapter to the [RabbitMQ](https://www.rabbitmq.com/) message queue server;
* `pg` (`0.21.0`), the adapter to the [PostgreSQL](https://www.postgresql.org/) database;
* `puma` (`3.11.0`), an application server;
* `rack` (`2.0.4`), a web-server interfacing library, on top of which `sinatra` has been built;
* `rake`(`12.3.0`), a dependencies management tool for ruby, similar to *make*;
* `sinatra` (`2.0.2`), a web framework for implementing efficient ruby APIs;
* `sinatra-activerecord` (`2.0.13`), 
* `sinatra-contrib` (`2.0.2`), several add-ons to `sinatra`;
* `sinatra-cross_origin` (`0.4.0`), a *middleware* to `sinatra` that helps in managing the [`Cross Origin Resource Sharing (CORS)`](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) problem;
* `sinatra-logger` (`0.3.2`), a *logger* *middleware*;

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
Developing this micro-service is easy.

Routes within the micro-service are defined in the [`config.ru`](https://github.com/sonata-nfv/tng-gtk-sp/blob/master/config.ru) file, in the root directory. It has two sections:

* The `require` section, where all used libraries must be required (**Note:** `controllers` had to be required explicitly, while `services` do not, due to a bug we have found to happened in some of the environments);
* The `map` section, where this micro-service's routes are mapped to the controller responsible for it.

This new or updated route can then be mapped either into an existing conctroller or imply writing a new controller. This new or updated controller can use either existing or newly written services to fullfil it's role.

For further details on the micro-service's architecture please check the [documentation](https://github.com/sonata-nfv/tng-gtk-sp/wiki/micro-service-architecture).

### Submiting changes
Changes to the repository can be requested using [this repository's issues](https://github.com/sonata-nfv/tng-gtk-sp/issues) and [pull requests](https://github.com/sonata-nfv/tng-gtk-sp/pulls) mechanisms.

## Versioning

The most up-to-date version is v4. For the versions available, see the [link to tags on this repository](https://github.com/sonata-nfv/tng-gtk-sp/releases).

## Configuration
The configuration of the micro-service is done through the following environment variables, defined in the [Dockerfile](https://github.com/sonata-nfv/tng-gtk-sp/blob/master/Dockerfile):

* `CATALOGUE_URL`, which defines the Catalogue's URL, where test descriptors are fetched from;
* `REPOSITORY_URL`, which defines the Repository's URL, where test plans and test results are fetched from;
* `DATABASE_URL`,  which defines the database's URL, in the following format: `postgresql://user:password@host:port/database_name` (**Note:** this is an alternative format to the one described in the [Installing from the Docker container](#installing-from-the-Docker-container) section);
* `MQSERVER_URL`,  which defines the message queue server's URL, in the following format: `amqp://user:password@host:port`

## Tests
Unit tests are defined for both `controllers` and `services`, in the `/spec` folder. Since we use `rspec` as the test library, we configure tests in the [`spec_helper.rb`](https://github.com/sonata-nfv/tng-gtk-sp/blob/master/spec/spec_helper.rb) file, also in the `/spec` folder.

These tests are executed by running the following command:
```shel
$ bundle exec rspec spec
```

Wider scope (integration and functional) tests involving this micro-service are defined in [`tng-tests`](https://github.com/sonata-nfv/tng-tests).

## Style guide
Our style guide is really simple:

1. We try to follow a [Clean Code](https://www.amazon.com/Clean-Code-Handbook-Software-Craftsmanship/dp/0132350882) philosophy in as much as possible, i.e., classes and methods should do one thing only, have the least number of parameters possible, etc.;
1. we use two spaces for identation.

## Api Reference

We have specified this micro-service's API in a [swagger](https://github.com/sonata-nfv/tng-gtk-sp/blob/master/doc/swagger.json)-formated file. Please check it there.

## Licensing

This 5GTANGO component is published under Apache 2.0 license. Please see the [LICENSE](https://github.com/sonata-nfv/tng-gtk-sp/blob/master/LICENSE) file for more details.

----
## Installing / Getting started

A quick introduction of the minimal setup you need to get a hello world up &
running.

```shell
commands here
```

Here you should say what actually happens when you execute the code above.

## Developing

### Built With
List main libraries, frameworks used including versions (React, Angular etc...)

### Prerequisites
What is needed to set up the dev environment. For instance, global dependencies or any other tools. include download links.


### Setting up Dev

This component has been developed in [ruby](https://ruby-lang.org), version `2.4.3`.

To get the code of this compoent you should execute the following `shell` commands:

```shell
git clone https://github.com/sonata-nfv/tng-gtk-common.git
cd tng-gtk-common/
bundle install
```

And state what happens step-by-step. If there is any virtual environment, local server or database feeder needed, explain here.

### Deploying / Publishing
give instructions on how to build and release a new version
In case there's some step you have to take that publishes this project to a
server, this is the right time to state it.

```shell
packagemanager deploy your-project -s server.com -u username -p password
```

And again you'd need to tell what the previous code actually does.

## Versioning

We can maybe use [SemVer](http://semver.org/) for versioning. For the versions available, see the [link to tags on this repository](/tags).


## Configuration

This component's configuration is done strictly through `ENV` variables.

The following `ENV` variables must be defined:

1. `CATALOGUE_URL`, which defines the `URL` to reach the [Catalogue](http://github.com/sonata-nfv/tng-cat), e.g., `http://tng-cat:4011/catalogues/api/v2`;
1. `UNPACKAGER_URL`, which defines the `URL` to reach the [Packager](https://github.com/sonata-nfv/tng-sdk-package), e.g.,`http://tng-sdk-package:5099/api/v1/packages`

Optionally, you can also define the following `ENV` variables:

1. `INTERNAL_CALLBACK_URL`, which defines the `URL` for the [Packager](https://github.com/sonata-nfv/tng-sdk-package) component to notify this component about the finishing of the upload process, defaults to `http://tng-gtk-common:5000/packages/on-change`;
1. `EXTERNAL_CALLBACK_URL`, which defines the `URL` that this component should call, when  it is notified (by the [Packager](https://github.com/sonata-nfv/tng-sdk-package) component) that the package has been on-boarded, e.g.,`http://tng-vnv-lcm:6100/api/v1/packages/on-change`. See details on this component's [Design documentation wiki page](https://github.com/sonata-nfv/tng-gtk-common/wiki/design-documentation);
1. `DEFAULT_PAGE_SIZE`: defines the default number of 'records' that are returned on a single query, for pagination purposes. If absent, a value of `100` is assumed;
1. `DEFAULT_PAGE_NUMBER`: defines the default page to start showing the selected records (beginning at `0`), for pagination purposes. If absent, a value of `0` is assumed;

## Tests

Describe and show how to run the tests with code examples.
Explain what these tests test and why.

```shell
Give an example
```

### Unit tests



## Style guide

Explain your code style and show how to check it.

## Api Reference

This component's API is documented in a [Swagger 2.0 file](https://github.com/sonata-nfv/tng-gtk-common/blob/master/doc/swagger.json). The current version does not support any form of authentication, since it is supposed to work with the [API Gateway](https://github.com/sonata-nfv/tng-api-gtw/) component in fron of it.

The current version supports an `api_root` like `http://pre-int-sp-ath.5gtango.eu:32003`. We are using the [`sinatra`](http://sinatrarb.com/) way of representing `URL` parameters, i.e., `:api_root`, `:package_uuid`, etc.

### Root
The root (`/`) API of this component can be accessed to return the API it implements (still a WiP).

```shell
$ curl :api_root/
```

### Pings
In order for the component to communicate it is alive, the following command can be issued:

```shell
$ curl :api_root/pings
```

An `HTTP` return code of `200` will indicate that the component is alive. In the current implementation, the answer will be a `Content-Type` of `application/json`, like in:

```json
{ "alive_since": "2018-05-14 10:53:41 UTC"}
```

### Packages
Packages constitute the unit for uploading information into the [Catalogue](http://github.com/sonata-nfv/tng-cat).

You can get examples of packages [here (the good one)](https://github.com/sonata-nfv/tng-sdk-package/blob/master/misc/5gtango-ns-package-example.tgo) and [here (the malformed one)](https://github.com/sonata-nfv/tng-sdk-package/blob/master/misc/5gtango-ns-package-example-malformed.tgo).

#### On-boarding
On-boarding (i.e., uploading) a package is an **asynchronous** process that involves several components until the package is stored in the [Catalogue](http://github.com/sonata-nfv/tng-cat):

1. the [API Gateway](https://github.com/sonata-nfv/tng-api-gtw/) component;
1. this component, the [Gatekeeper Common](https://github.com/sonata-nfv/tng-gtk-common/);
1. the [Packager](https://github.com/sonata-nfv/tng-sdk-package) component;
1. and the already mentioned [Catalogue](http://github.com/sonata-nfv/tng-cat).

On-boarding a package can be done by the following command:

```shell
$ curl -X POST :api_root/packages -F "package=@./5gtango-ns-package-example.tgo"
```

 The `package` field is the only one that is mandatory, but there are a number of optional ones that you can check [here](https://github.com/sonata-nfv/tng-sdk-package).
 
 Expected returned data is:

 * `HTTP` code `200` (`Ok`) if the package is accepted for processing, with a `JSON` object including the `package_processing_uuid` (see Querying the status, below);
 * `HTTP` code `400` (`Bad Request`), if the file is not found, has the wrong `MEDIA` type, etc. 
  
#### Querying

We may query the on-boarding process by issuing

```shell
$ curl :api_root/packages/status/:package_processing_uuid
```

Expected returned data is:

* `HTTP` code `200` (`Ok`) if the package processing `UUID` is found, with the processing status in the body (`JSON` format);
* `HTTP` code `400` (`Bad Request`), if the `:package_processing_uuid` is mal-formed;
* `HTTP` code `404` (`Not Found`), if the package processing is not found.

Querying all existing packages can be done using the following command (default values for `DEFAULT_PAGE_SIZE` and `DEFAULT_PAGE_NUMBER` mentioned above are used):

```shell
$ curl :api_root/packages
```

If different default values for the starting page number and the number of records per page are needed, these can be used as query parameters:

```shell
$ curl ":api_root/packages?page_size=20&page_number=2"
```

Note the `""` used around the command, in order for the `shell` used to consider the `&` as part of the command, instead of considering it a background process command.

Expected returned data is:

* `HTTP` code `200` (`Ok`) with an array of package's metadata in the body (`JSON` format), or an empty array (`[]`) if none is found according to the parameters passed;

A specific package's metadata can be fetched using the following command:

```shell
$ curl :api_root/packages/:package_uuid
```

Expected returned data is:

* `HTTP` code `200` (`Ok`) if the package is found, with the package's metadata in the body (`JSON` format);
* `HTTP` code `400` (`Bad Request`), if the `:package_uuid` is mal-formed;
* `HTTP` code `404` (`Not Found`), if the package is not found.

In case we want to download the package's file, we can use the following command:

```shell
$ curl :api_root/packages/:package_uuid/package-file
```

Expected returned data is:

* `HTTP` code `200` (`Ok`) if the package is found, with the package's file in the body (binary format);
* `HTTP` code `400` (`Bad Request`), if the `:package_uuid` is mal-formed;
* `HTTP` code `404` (`Not Found`), if the package is not found.

In case we want to download the any of the other files the package may contain, we can use the following command, where the `:file_uuid` can be fetched from the packages metada:

```shell
$ curl :api_root/packages/:package_uuid/files/:file_uuid
```

Expected returned data is:

* `HTTP` code `200` (`Ok`) if the file is found, with its content in the body (binary format);
* `HTTP` code `400` (`Bad Request`), if the `:package_uuid` or `:file_uuid` is mal-formed;
* `HTTP` code `404` (`Not Found`), if the package or the file is not found.

#### Deleting

We may delete an on-boarded package by issuing the following command:

```shell
$ curl -X DELETE :api_root/packages/:package_uuid
```

Expected returned data is:

* `HTTP` code `204` (`No Content`) if the package is found and successfuly deleted (the body will be empty);
* `HTTP` code `400` (`Bad Request`), if the `:package_uuid` is mal-formed;
* `HTTP` code `404` (`Not Found`), if the package is not found.

#### Options

We may query which operations are allowed with the `HTTP` verb `OPTIONS`, by issuing the following command:

```shell
$ curl -X OPTIONS :api_root/packages

* `HTTP` code `200` (`No Content`) if the package options are defined;

### Services
Are are on-boarded within packages (see above), so one can not `POST`, `PUT`, `PATCH` or `DELETE` them.

#### Querying

Querying all existing services can be done using the following command (default values for `DEFAULT_PAGE_SIZE` and `DEFAULT_PAGE_NUMBER` mentioned above are used):

```shell
$ curl :api_root/services
```

If different default values for the starting page number and the number of records per page are needed, these can be used as query parameters:

```shell
$ curl ":api_root/services?page_size=20&page_number=2"
```

Note the `""` used around the command, in order for the `shell` used to consider the `&` as part of the command, instead of considering it a background process command.

Expected returned data is:

* `HTTP` code `200` (`Ok`) with an array of services' metadata in the body (`JSON` format), or an empty array (`[]`) if none is found according to the parameters passed;

A specific service's metadata can be fetched using the following command:

```shell
$ curl :api_root/services/:service_uuid
```

Expected returned data is:

* `HTTP` code `200` (`Ok`) if the service is found, with the service's metadata in the body (`JSON` format);
* `HTTP` code `400` (`Bad Request`), if the `:service_uuid` is mal-formed;
* `HTTP` code `404` (`Not Found`), if the service is not found.

#### Options

We may query which operations are allowed with the `HTTP` verb `OPTIONS`, by issuing the following command:

```shell
$ curl -X OPTIONS :api_root/services
```

* `HTTP` code `200` (`No Content`) if the services options are defined;

## Database

Explaining what database (and version) has been used. Provide download links.
Documents your database design and schemas, relations etc... 

## Licensing

This software has an [Apache2.0](https://github.com/sonata-nfv/tng-gtk-common/blob/master/LICENSE) license.
