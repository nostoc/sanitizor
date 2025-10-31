# Music Discovery Dashboard

This example demonstrates how to build a music discovery dashboard that integrates with Apple Music to search for songs, albums, and artists, providing users with comprehensive music discovery capabilities.

## Prerequisites

1. **Apple Music Setup**
   > Refer the [Apple Music setup guide](https://central.ballerina.io/ballerinax/apple.music) here.

2. For this example, create a `Config.toml` file with your credentials:

```toml
# Apple Music API configuration
# Note: Apple Music uses JWT-based authentication with developer tokens
# You'll need to generate a developer token from your Apple Developer account
developerToken = "<Your Apple Music Developer Token>"
```

## Run the Example

Execute the following command to run the example. The script will print its progress to the console.

```shell
bal run
```

The application will start the music discovery dashboard and demonstrate various Apple Music API operations such as searching for tracks, albums, and artists, and displaying the results in a structured format.