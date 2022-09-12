
# PORTL Commons

Common library code shared by the PORTL Event API and Admin API projects.

## Dependencies

JDK 1.8
Scala 2.12
MongoDB 3.4

## Building and running:

We use an internal Nexus server as a Maven proxy for build reproduceability. When running sbt, configure it with the
repositories definition file at the project root. Setting -Dsbt.override.build.repos=true prevents sbt from using the
default repos in addition to the ones we've defined.

    sbt -Dsbt.repository.config=repositories -Dsbt.override.build.repos=true

## IntelliJ Setup

Import as SBT project.

Configure sbt command line flags (shown in previous section of this readme) in settings:

File | Settings | Build, Execution, Deployment | Build Tools | sbt | JVM Options | VM Parameters
