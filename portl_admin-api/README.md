
# PORTL Admin API Server


## Dependencies

JDK 1.8
Scala 2.12
MongoDB 3.4


## Local setup

Copy local.conf.example to local.conf and replace with correct values.


## Building and running:

Note that this depends on an external library for model code that is shared with another project (admin api). When
running sbt, configure it with the repositories definition file at the project root. Setting
-Dsbt.override.build.repos=true prevents sbt from using the default repos in addition to the ones we've defined. You
should also specify a local config file.

Note: there is a [known issue](https://github.com/kamon-io/sbt-aspectj-runner/issues/22) with config loading when using
the Kamon aspectJ runner. Be sure to specify `config.file` instead of `config.resource`.

    sbt -Dconfig.file=src/main/resources/local.conf -Dsbt.repository.config=repositories -Dsbt.override.build.repos=true


## IntelliJ Setup

Import as SBT project.

Configure sbt command line flags (shown in previous section of this readme) in settings:

File | Settings | Build, Execution, Deployment | Build Tools | sbt | JVM Options | VM Parameters


## Logging

If `logging.graylog.env` is defined, logs go to `logging.graylog.host` (logs.portl.com by default). If
`logging.graylog.env` is not defined, logs go to console plus logs/application.log. Note these graylog properties
must be set as system properties (pass in with `-D`). They will not work if set in application.conf.
