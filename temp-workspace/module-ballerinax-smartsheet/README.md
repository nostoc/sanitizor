# Ballerina Smartsheet connector

[![Build](https://github.com/ballerina-platform/module-ballerinax-smartsheet/actions/workflows/ci.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-smartsheet/actions/workflows/ci.yml)
[![Trivy](https://github.com/ballerina-platform/module-ballerinax-smartsheet/actions/workflows/trivy-scan.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-smartsheet/actions/workflows/trivy-scan.yml)
[![GraalVM Check](https://github.com/ballerina-platform/module-ballerinax-smartsheet/actions/workflows/build-with-bal-test-graalvm.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-smartsheet/actions/workflows/build-with-bal-test-graalvm.yml)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerinax-smartsheet.svg)](https://github.com/ballerina-platform/module-ballerinax-smartsheet/commits/master)
[![GitHub Issues](https://img.shields.io/github/issues/ballerina-platform/ballerina-library/module/smartsheet.svg?label=Open%20Issues)](https://github.com/ballerina-platform/ballerina-library/labels/module%smartsheet)

## Overview

[Smartsheet](https://www.smartsheet.com/) is a cloud-based platform that enables teams to plan, capture, manage, automate, and report on work at scale, empowering you to move from idea to impact, fast.

The `ballerinax/smartsheet` package offers APIs to connect and interact with [Smartsheet API](https://developers.smartsheet.com/api/smartsheet/introduction) endpoints, specifically based on [Smartsheet API v2.0](https://developers.smartsheet.com/api/smartsheet/openapi).


## Setup guide

To use the Smartsheet connector, you must have access to the Smartsheet API through a [Smartsheet developer account](https://developers.smartsheet.com/) and obtain an API access token. If you do not have a Smartsheet account, you can sign up for one [here](https://www.smartsheet.com/try-it).

### Step 1: Create a Smartsheet Account

1. Navigate to the [Smartsheet website](https://www.smartsheet.com/) and sign up for an account or log in if you already have one.

2. Ensure you have a Business or Enterprise plan, as the Smartsheet API is restricted to users on these plans.

### Step 2: Generate an API Access Token

1. Log in to your Smartsheet account.

2. On the left Navigation Bar at the bottom, select Account (your profile image), then Personal Settings.

3. In the new window, navigate to the API Access tab and select Generate new access token.

![generate API token ](https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-smartsheet/refs/heads/main/docs/setup/resources/generate-api-token.png)


> **Tip:** You must copy and store this key somewhere safe. It won't be visible again in your account settings for security reasons

## Quickstart

To use the Smartsheet connector in your Ballerina application, update the `.bal` file as follows:

### Step 1: Import the module

Import the `smartsheet` module.

```ballerina
import ballerinax/smartsheet;
```

### Step 2: Instantiate a new connector

1. Create a `Config.toml` file and configure the obtained access token as follows:

```toml
token = "<Your_Smartsheet_Access_Token>"
```

2. Create a `smartsheet:ConnectionConfig` with the obtained access token and initialize the connector with it.

```ballerina
configurable string token = ?;

final smartsheet:Client smartsheet = check new({
    auth: {
        token
    }
});
```

### Step 3: Invoke the connector operation

Now, utilize the available connector operations.

#### Create a new sheet

```ballerina
public function main() returns error? {
    smartsheet:SheetsBody newSheet = {
        name: "New Project Sheet",
        columns: [
            {
                title: "Task Name",
                type: "TEXT_NUMBER",
                primary: true
            },
            {
                title: "Status",
                type: "PICKLIST",
                options: ["Not Started", "In Progress", "Complete"]
            },
            {
                title: "Due Date",
                type: "DATE"
            }
        ]
    };

    smartsheet:WebhookResponse response = check smartsheet->/sheets.post(newSheet);
}
```

### Step 4: Run the Ballerina application

```bash
bal run
```


## Examples

The `Smartsheet` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-smartsheet/tree/main/examples), covering the following use cases:

1. [Project task management](https://github.com/ballerina-platform/module-ballerinax-smartsheet/tree/main/examples/project_task_management) - Demonstrates how to automate project task creation using Ballerina connector for Smartsheet.

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

* For more information go to the [`smartsheet` package](https://central.ballerina.io/ballerinax/smartsheet/latest).
* For example demonstrations of the usage, go to [Ballerina By Examples](https://ballerina.io/learn/by-example/).
* Chat live with us via our [Discord server](https://discord.gg/ballerinalang).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
