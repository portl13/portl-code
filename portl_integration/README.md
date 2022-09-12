# PORTL Integration Tests

This project references and supports the PORTL backend services.

## Requirements

- [docker](https://docs.docker.com) 18.09.0
- [docker-compose](https://docs.docker.com/compose/) 1.23.1

## Setup

Images referenced in `docker-compose.yml` must be available, including:
 
- [portl/api](https://bitbucket.concentricsky.com/projects/PORTL/repos/api/browse) 
- [portl/admin-api](https://bitbucket.concentricsky.com/projects/PORTL/repos/admin-api/browse)

Building PORTL docker images generally requires something like the following. More specific instructions may exist in
each project.

    sbt publishLocal && docker build -t portl/api .

## Running an application cluster

This runs a PORTL API on port 12000 and an Admin API on port 12001 with shared database and monitoring.

    docker-compose up

## Running load tests

Edit the target configuration in src/it/scala/com/portl/test/integration/BasicSimulation.scala, including baseURL, to
point at the local cluster, staging environment, etc.

TODO : externalize this config.

    sbt gatling-it:test

## Running integration tests

Update config located in src/test/resources/application.properties to point at the correct environment.

    sbt gatling:test
