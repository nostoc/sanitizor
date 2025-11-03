# Music Recommendation Engine

This example demonstrates how to build a music recommendation engine using the Apple Music API to search for songs, retrieve artist information, and create personalized playlists based on user preferences.

## Prerequisites

1. **Apple Music Setup**
   > Refer the [Apple Music setup guide](https://central.ballerina.io/ballerinax/apple.music) here.

2. For this example, create a `Config.toml` file with your credentials:

```toml
# Apple Music API configuration
developerToken = "<Your Apple Music Developer Token>"
userToken = "<Your Apple Music User Token>"
```

## Run the example

Execute the following command to run the example. The script will print its progress to the console.

```shell
bal run
```

The application will:
- Connect to the Apple Music API
- Search for songs based on predefined criteria
- Analyze music preferences
- Generate personalized recommendations
- Display the recommended tracks and artists