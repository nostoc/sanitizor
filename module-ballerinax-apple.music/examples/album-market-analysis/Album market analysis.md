# Album Market Analysis

This example demonstrates how to analyze album availability and popularity across different Apple Music markets by fetching album data from multiple storefronts and generating market penetration insights.

## Prerequisites

1. **Apple Music Setup**
   > Refer the [Apple Music setup guide](https://central.ballerina.io/ballerinax/apple.music/latest#setup-guide) here.

2. For this example, create a `Config.toml` file with your credentials:

```toml
developerToken = "<Your Developer Token>"
```

## Run the Example

Execute the following command to run the example. The script will print its progress to the console.

```shell
bal run
```

The script will:
- Fetch album data from multiple Apple Music storefronts (US, GB, JP, DE, FR, AU)
- Display detailed album information for each market
- Provide a regional availability summary
- Generate market penetration insights and recommendations