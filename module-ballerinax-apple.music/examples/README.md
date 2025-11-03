# Examples

The `apple.music` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-apple.music/tree/main/examples), covering use cases like music discovery and music recommendation systems.

1. [Music discovery engine](https://github.com/ballerina-platform/module-ballerinax-apple.music/tree/main/examples/music-discovery-engine) - Build a music discovery engine to help users find new songs and artists based on their preferences.

2. [Music recommendation engine](https://github.com/ballerina-platform/module-ballerinax-apple.music/tree/main/examples/music-recommendation-engine) - Create a personalized music recommendation system that suggests tracks based on user listening history and preferences.

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