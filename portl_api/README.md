
# PORTL Event API Server


## Dependencies

JDK 1.8
Scala 2.12
MongoDB 3.4


## Local setup

Copy local.conf.example to local.conf and replace with correct values.

Run index creation script against local mongo:

    ./src/scripts/createSchema.sh

## Building and running:

Note that this depends on an external library for model code that is shared with another project (admin api). When
running sbt, configure it with the repositories definition file at the project root. Setting
-Dsbt.override.build.repos=true prevents sbt from using the default repos in addition to the ones we've defined. You
should also specify a local config file.

    sbt -Dconfig.resource=local.conf -Dsbt.repository.config=repositories -Dsbt.override.build.repos=true


## IntelliJ Setup

Import as SBT project.

Configure sbt command line flags (shown in previous section of this readme) in settings:

File | Settings | Build, Execution, Deployment | Build Tools | sbt | JVM Options | VM Parameters


## Gatling load tests

This project includes the Gatling SBT plugin. More info here:

https://gatling.io/docs/current/quickstart/

https://gatling.io/docs/current/extensions/sbt_plugin/

To record a scenario, use `sbt gatling-it:startRecorder`. If using the iOS simulator, you can use Charles proxy with an
external proxy config to route traffic through the gatling recorder proxy.

To run load tests, run `sbt gatling-it:test`. Target domain configuration tbd.
