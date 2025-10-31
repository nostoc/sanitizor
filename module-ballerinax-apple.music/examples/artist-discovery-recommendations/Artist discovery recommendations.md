# Artist Discovery Recommendations

This example demonstrates how to discover and retrieve music recommendations using the Apple Music API to search for artists and get related music content.

## Prerequisites

1. **Apple Music Setup**
   > Refer the [Apple Music setup guide](https://central.ballerina.io/ballerinax/apple.music) here.

2. For this example, create a `Config.toml` file with your credentials:

```toml
# Apple Music API configuration
# Add your Apple Music API credentials here
token = "<Your Apple Music API Token>"
```

## Run the example

Execute the following command to run the example. The script will print its progress to the console.

```shell
bal run
```

The application will search for artists and display music recommendations based on the Apple Music catalog.