
# Ballerina supabase connector

[![Build](https://github.com/ballerina-platform/module-ballerinax-supabase/actions/workflows/ci.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-supabase/actions/workflows/ci.yml)
[![Trivy](https://github.com/ballerina-platform/module-ballerinax-supabase/actions/workflows/trivy-scan.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-supabase/actions/workflows/trivy-scan.yml)
[![GraalVM Check](https://github.com/ballerina-platform/module-ballerinax-supabase/actions/workflows/build-with-bal-test-graalvm.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-supabase/actions/workflows/build-with-bal-test-graalvm.yml)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerinax-supabase.svg)](https://github.com/ballerina-platform/module-ballerinax-supabase/commits/master)
[![GitHub Issues](https://img.shields.io/github/issues/ballerina-platform/ballerina-library/module/supabase.svg?label=Open%20Issues)](https://github.com/ballerina-platform/ballerina-library/labels/module%supabase)

## Overview

[Supabase](https://supabase.com/) is an open-source Firebase alternative that provides a complete backend-as-a-service platform with real-time databases, authentication, instant APIs, edge functions, and storage solutions for building modern applications.

The `ballerinax/supabase` package offers APIs to connect and interact with [Supabase API](https://supabase.com/docs/reference/api) endpoints, specifically based on [Supabase Management API v1](https://supabase.com/docs/reference/api/introduction).
## Setup guide

To use the Supabase connector, you must have access to the Supabase API through a [Supabase project](https://supabase.com/docs) and obtain an API key. If you do not have a Supabase account, you can sign up for one [here](https://supabase.com).

### Step 1: Create a Supabase Account

1. Navigate to the [Supabase website](https://supabase.com) and sign up for an account or log in if you already have one.

2. Create a new project or select an existing project. API access is available on all Supabase plans, including the free tier.

### Step 2: Generate an API Key

1. Log in to your Supabase account and navigate to your project dashboard.

2. In the left sidebar, click on Settings, then select API from the settings menu.

3. In the API settings page, you will find your project API keys including the `anon` public key and `service_role` secret key under the Project API keys section.

> **Tip:** You must copy and store this key somewhere safe. It won't be visible again in your account settings for security reasons.
## Quickstart

To use the `supabase` connector in your Ballerina application, update the `.bal` file as follows:

### Step 1: Import the module

```ballerina
import ballerinax/supabase;
```

### Step 2: Instantiate a new connector

1. Create a `Config.toml` file and configure the obtained access token:

```toml
token = "<Your_Supabase_Access_Token>"
```

2. Create a `supabase:ConnectionConfig` and initialize the client:

```ballerina
configurable string token = ?;

final supabase:Client supabaseClient = check new({
    auth: {
        token
    }
}, "<Your_Supabase_API_URL>");
```

### Step 3: Invoke the connector operation

Now, utilize the available connector operations.

#### Create a new project

```ballerina
public function main() returns error? {
    supabase:V1CreateProjectBody newProject = {
        name: "My New Project",
        organizationId: "your-org-id",
        dbPass: "securePassword123",
        regionSelection: {
            'type: "specific",
            code: "us-east-1"
        }
    };

    supabase:V1ProjectResponse response = check supabaseClient->/v1/projects.post(newProject);
}
```

### Step 4: Run the Ballerina application

```bash
bal run
```
## Examples

The `supabase` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-supabase/tree/main/examples), covering the following use cases:

1. [Security monitoring setup](https://github.com/ballerina-platform/module-ballerinax-supabase/tree/main/examples/security-monitoring-setup) - Demonstrates how to configure and implement security monitoring for Supabase applications.
2. [Database migration workflow](https://github.com/ballerina-platform/module-ballerinax-supabase/tree/main/examples/database-migration-workflow) - Illustrates the process of migrating databases using Supabase connector.
3. [Database upgrade workflow](https://github.com/ballerina-platform/module-ballerinax-supabase/tree/main/examples/database-upgrade-workflow) - Shows how to perform database upgrades through automated workflows.
4. [Branch cleanup workflow](https://github.com/ballerina-platform/module-ballerinax-supabase/tree/main/examples/branch-cleanup-workflow) - Demonstrates automated cleanup of database branches in development environments.
## Build from the source

### Setting up the prerequisites

1. Download and install Java SE Development Kit (JDK) version 17. You can download it from either of the following sources:

    * [Oracle JDK](https://www.oracle.com/java/technologies/downloads/)
    * [OpenJDK](https://adoptium.net/)

    > **Note:** After installation, remember to set the `JAVA_HOME` environment variable to the directory where JDK was installed.

2. Download and install [Ballerina Swan Lake](https://ballerina.io/).

3. Download and install [Docker](https://www.docker.com/get-started).

    > **Note**: Ensure that the Docker daemon is running before executing any tests.

4. Export Github Personal access token with read package permissions as follows,

    ```bash
    export packageUser=<Username>
    export packagePAT=<Personal access token>
    ```

### Build options

Execute the commands below to build from the source.

1. To build the package:

    ```bash
    ./gradlew clean build
    ```

2. To run the tests:

    ```bash
    ./gradlew clean test
    ```

3. To build the without the tests:

    ```bash
    ./gradlew clean build -x test
    ```

4. To run tests against different environments:

    ```bash
    ./gradlew clean test -Pgroups=<Comma separated groups/test cases>
    ```

5. To debug the package with a remote debugger:

    ```bash
    ./gradlew clean build -Pdebug=<port>
    ```

6. To debug with the Ballerina language:

    ```bash
    ./gradlew clean build -PbalJavaDebug=<port>
    ```

7. Publish the generated artifacts to the local Ballerina Central repository:

    ```bash
    ./gradlew clean build -PpublishToLocalCentral=true
    ```

8. Publish the generated artifacts to the Ballerina Central repository:

    ```bash
    ./gradlew clean build -PpublishToCentral=true
    ```

## Contribute to Ballerina

As an open-source project, Ballerina welcomes contributions from the community.

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of conduct

All the contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).


## Useful links

* For more information go to the [`supabase` package](https://central.ballerina.io/ballerinax/supabase/latest).
* For example demonstrations of the usage, go to [Ballerina By Examples](https://ballerina.io/learn/by-example/).
* Chat live with us via our [Discord server](https://discord.gg/ballerinalang).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
