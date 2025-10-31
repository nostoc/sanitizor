# Music Discovery Recommendations

This example demonstrates how to build a music discovery and recommendation system using the Apple Music API to search for tracks, retrieve detailed song information, and generate personalized music recommendations.

## Prerequisites

1. **Apple Music Setup**
   > Refer to the [Apple Music setup guide](https://central.ballerina.io/ballerinax/apple.music/latest#setup-guide) to obtain the necessary credentials and configure your Apple Music developer account.

2. For this example, create a `Config.toml` file with your credentials:

```toml
# Apple Music API Configuration
developerToken = "<Your Apple Music Developer Token>"
userToken = "<Your Apple Music User Token>"
```

## Run the example

Execute the following command to run the example. The script will demonstrate music discovery capabilities by searching for tracks, retrieving song details, and generating recommendations based on your music preferences.

```shell
bal run
```

The application will:
- Search for music tracks based on specified criteria
- Retrieve detailed information about discovered songs
- Generate personalized music recommendations
- Display the results with track details, artist information, and recommendation scores