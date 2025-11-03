## Overview

[Apple Music](https://music.apple.com/) is Apple's streaming music service that provides access to millions of songs, curated playlists, and personalized recommendations, allowing users to discover and enjoy music across all their devices.

The `ballerinax/apple.music` package offers APIs to connect and interact with [Apple Music API](https://developer.apple.com/documentation/applemusicapi) endpoints, specifically based on [Apple Music API v1](https://developer.apple.com/documentation/applemusicapi).
I'll research the Apple Music API requirements and generate the setup guide following your specifications.

## Setup guide

To use the Apple Music connector, you must have access to the Apple Music API through an [Apple Developer account](https://developer.apple.com/apple-music/api/) and obtain API credentials including a developer token. If you do not have an Apple ID, you can sign up for one [here](https://appleid.apple.com/account).

### Step 1: Create an Apple Developer Account

1. Navigate to the [Apple Developer website](https://developer.apple.com/) and sign up for an account or log in if you already have one.

2. Ensure you have an active Apple Developer Program membership ($99/year), as the Apple Music API requires enrollment in the Apple Developer Program.

### Step 2: Generate API Credentials

1. Log in to your Apple Developer account.

2. Navigate to Certificates, Identifiers & Profiles in the developer portal.

3. Under Keys, select the "+" button to create a new key.

4. Enable MusicKit and provide a key name, then register the key.

5. Download the private key file (.p8) and note the Key ID - you'll need both to generate developer tokens for API authentication.

> **Tip:** You must copy and store this key somewhere safe. It won't be visible again in your account settings for security reasons.
## Quickstart

To use the `apple.music` connector in your Ballerina application, update the `.bal` file as follows:

### Step 1: Import the module

```ballerina
import ballerinax/apple.music as appleMusic;
```

### Step 2: Instantiate a new connector

1. Create a `Config.toml` file and configure the obtained access tokens:

```toml
authorization = "<Your_Apple_Music_JWT_Token>"
musicUserToken = "<Your_Apple_Music_User_Token>"
```

2. Create an `appleMusic:ApiKeysConfig` and initialize the client:

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
        ids: ["1234567890"]
    });
}
```

### Step 4: Run the Ballerina application

```bash
bal run
```
## Examples

The `apple.music` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-apple.music/tree/main/examples), covering the following use cases:

1. [Music discovery engine](https://github.com/ballerina-platform/module-ballerinax-apple.music/tree/main/examples/music-discovery-engine) - Demonstrates how to build a music discovery system using Ballerina connector for Apple Music.
2. [Music recommendation engine](https://github.com/ballerina-platform/module-ballerinax-apple.music/tree/main/examples/music-recommendation-engine) - Illustrates creating personalized music recommendations based on user preferences.