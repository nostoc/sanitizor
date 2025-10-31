
# Ballerina apple.music connector

[![Build](https://github.com/ballerina-platform/module-ballerinax-apple.music/actions/workflows/ci.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-apple.music/actions/workflows/ci.yml)
[![Trivy](https://github.com/ballerina-platform/module-ballerinax-apple.music/actions/workflows/trivy-scan.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-apple.music/actions/workflows/trivy-scan.yml)
[![GraalVM Check](https://github.com/ballerina-platform/module-ballerinax-apple.music/actions/workflows/build-with-bal-test-graalvm.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-apple.music/actions/workflows/build-with-bal-test-graalvm.yml)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerinax-apple.music.svg)](https://github.com/ballerina-platform/module-ballerinax-apple.music/commits/master)
[![GitHub Issues](https://img.shields.io/github/issues/ballerina-platform/ballerina-library/module/apple.music.svg?label=Open%20Issues)](https://github.com/ballerina-platform/ballerina-library/labels/module%apple.music)

## Overview

[Apple Music](https://www.apple.com/apple-music/) is a music streaming service that offers access to over 100 million songs, curated playlists, radio stations, and exclusive content, providing users with a comprehensive music discovery and listening experience across all their devices.

The `ballerinax/apple.music` package offers APIs to connect and interact with [Apple Music API](https://developer.apple.com/documentation/applemusicapi) endpoints, specifically based on [Apple Music API v1](https://developer.apple.com/documentation/applemusicapi).
## Setup guide

To use the Apple Music connector, you must have access to the Apple Music API through an [Apple Developer account](https://developer.apple.com/) and obtain API credentials including a private key and key ID. If you do not have an Apple ID, you can sign up for one [here](https://appleid.apple.com/account).

### Step 1: Create an Apple Developer Account

1. Navigate to the [Apple Developer website](https://developer.apple.com/) and sign up for an account or log in if you already have one.

2. Ensure you have an active Apple Developer Program membership ($99/year), as the Apple Music API requires enrollment in the Apple Developer Program.

### Step 2: Generate API Credentials

1. Log in to your Apple Developer account.

2. Navigate to Certificates, Identifiers & Profiles, then select Keys from the sidebar.

3. Click the "+" button to create a new key, provide a name for your key, and select "MusicKit" from the list of services.

4. Click Continue, then Register to generate your private key file (.p8) and obtain your Key ID.

5. Note your Team ID from your Apple Developer account membership details, as this will be required along with your Key ID and private key for authentication.

> **Tip:** You must copy and store this key somewhere safe. It won't be visible again in your account settings for security reasons.
## Quickstart

To use the `apple.music` connector in your Ballerina application, update the `.bal` file as follows:

### Step 1: Import the module

```ballerina
import ballerinax/apple.music as appleMusic;
```

### Step 2: Instantiate a new connector

1. Create a `Config.toml` file and configure the obtained access token:

```toml
authorization = "<Your_Apple_Music_JWT_Token>"
musicUserToken = "<Your_Apple_Music_User_Token>"
```

2. Create a `appleMusic:ApiKeysConfig` and initialize the client:

```ballerina
configurable string authorization = ?;
configurable string musicUserToken = ?;

final appleMusic:Client appleMusicClient = check new({
    authorization,
    musicUserToken
});
```

### Step 3: Invoke the connector operation

Now, utilize the available connector operations.

#### Add a resource to library

```ballerina
public function main() returns error? {
    check appleMusicClient->/me/library.post({
        ids: ["1441164494"]
    });
}
```

### Step 4: Run the Ballerina application

```bash
bal run
```
## Examples

The `apple.music` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-apple.music/tree/main/examples), covering the following use cases:

1. [Regional music discovery](https://github.com/ballerina-platform/module-ballerinax-apple.music/tree/main/examples/regional-music-discovery) - Demonstrates how to discover music content based on regional preferences and availability.
2. [Music discovery dashboard](https://github.com/ballerina-platform/module-ballerinax-apple.music/tree/main/examples/music-discovery-dashboard) - Illustrates creating a dashboard for exploring and discovering new music content.
3. [Music discovery recommendations](https://github.com/ballerina-platform/module-ballerinax-apple.music/tree/main/examples/music-discovery-recommendations) - Shows how to generate personalized music recommendations for users.
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

* For more information go to the [`apple.music` package](https://central.ballerina.io/ballerinax/apple.music/latest).
* For example demonstrations of the usage, go to [Ballerina By Examples](https://ballerina.io/learn/by-example/).
* Chat live with us via our [Discord server](https://discord.gg/ballerinalang).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
