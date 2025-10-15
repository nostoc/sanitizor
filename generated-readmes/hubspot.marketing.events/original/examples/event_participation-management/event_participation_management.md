# Event Participation Management

This example demonstrates how to manage event participation using HubSpot's Marketing Events API to create events and register attendees.

## Prerequisites

1. **HubSpot Setup**
   > Refer to the [HubSpot setup guide](https://central.ballerina.io/ballerinax/hubspot.marketing.events/latest#setup-guide) to obtain the necessary credentials.

2. For this example, create a `Config.toml` file with your credentials:

```toml
clientId = "<Your Client ID>"
clientSecret = "<Your Client Secret>"
refreshToken = "<Your Refresh Token>"
```

## Run the example

Execute the following command to run the example. The script will demonstrate event creation and participant management operations, printing the results to the console.

```shell
bal run
```

The example will show you how to:
- Create marketing events in HubSpot
- Manage event participants and their registration status
- Retrieve event details and participant information