# Examples

The `apple.music` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-apple.music/tree/main/examples), covering use cases like regional music discovery, music discovery dashboard, and music discovery recommendations.

1. [Regional music discovery](https://github.com/ballerina-platform/module-ballerinax-apple.music/tree/main/examples/regional-music-discovery) - Discover popular music content from specific geographic regions using Apple Music's regional charts and recommendations.

2. [Music discovery dashboard](https://github.com/ballerina-platform/module-ballerinax-apple.music/tree/main/examples/music-discovery-dashboard) - Build a comprehensive dashboard that displays trending songs, albums, and artists from Apple Music's catalog.

3. [Music discovery recommendations](https://github.com/ballerina-platform/module-ballerinax-apple.music/tree/main/examples/music-discovery-recommendations) - Generate personalized music recommendations based on user preferences and listening history using Apple Music's recommendation engine.

## Prerequisites

1. Generate Apple Music credentials to authenticate the connector as described in the [Setup guide](https://central.ballerina.io/ballerinax/apple.music/latest#setup-guide).

2. For each example, create a `Config.toml` file the related configuration. Here's an example of how your `Config.toml` file should look:

    ```toml
    token = "<Access Token>"
    ```

## Running an Example

Execute the following commands to build an example from the source:

* To build an example:

    ```bash
    bal build
    ```

* To run an example:

    ```bash
    bal run
    ```