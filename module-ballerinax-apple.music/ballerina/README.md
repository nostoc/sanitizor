## Overview

[Apple Music](https://music.apple.com/) is Apple's music streaming service that provides access to millions of songs, curated playlists, and personalized recommendations, offering users a comprehensive music discovery and listening experience across all Apple devices.

The `ballerinax/apple.music` package offers APIs to connect and interact with [Apple Music API](https://developer.apple.com/documentation/applemusicapi) endpoints, specifically based on a recent version of the API.
## Setup guide

To use the Apple Music connector, you must have access to the Apple Music API through an [Apple Developer account](`https://developer.apple.com/`) and obtain an API key. If you do not have an Apple ID, you can sign up for one [here](`https://appleid.apple.com/account`).

### Step 1: Create an Apple Developer Account

1. Navigate to the [Apple Developer website](`https://developer.apple.com/`) and sign up for a developer account or log in if you already have one.

2. Ensure you have a paid Apple Developer Program membership ($99/year), as the Apple Music API requires an active developer program enrollment to generate the necessary certificates and keys.

### Step 2: Generate an API Key

1. Log in to your Apple Developer account.

2. Navigate to Certificates, Identifiers & Profiles, then select Keys from the left sidebar.

3. Click the "+" button to create a new key, provide a name for your key, and select "MusicKit" from the list of services.

4. Click Continue, then Register to generate your key.

5. Download the .p8 key file and note your Key ID and Team ID, as you'll need all three components to authenticate with the Apple Music API.

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
        ids: ["songs:123456789"]
    });
}
```

### Step 4: Run the Ballerina application

```bash
bal run
```
## Examples

The `apple.music` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-apple.music/tree/main/examples), covering the following use cases:

1. [Artist discovery recommendations](https://github.com/ballerina-platform/module-ballerinax-apple.music/tree/main/examples/artist-discovery-recommendations) - Demonstrates how to discover and retrieve artist recommendations using the Apple Music API.
2. [Music discovery recommendations](https://github.com/ballerina-platform/module-ballerinax-apple.music/tree/main/examples/music-discovery-recommendations) - Illustrates how to find and get music recommendations based on user preferences.