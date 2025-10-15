# Sign Up Form

This example demonstrates how to create, update, retrieve, and delete HubSpot marketing forms using Ballerina. The system creates a sign-up form with email field, updates it to include additional fields like first name, last name, phone number, and address, then retrieves the form details and finally deletes it.

## Prerequisites

1. **HubSpot Setup**
   - Create a HubSpot account
   - Set up OAuth2 authentication and obtain client credentials
   - Generate a refresh token for API access

   > Refer the [HubSpot Marketing Forms setup guide](https://github.com/ballerina-platform/module-ballerinax-hubspot.marketing.forms/blob/main/ballerina/README.md) here.

2. For this example, create a `Config.toml` file with your credentials. Here's an example of how your `Config.toml` file should look:

```toml
clientId = "YOUR_HUBSPOT_CLIENT_ID"
clientSecret = "YOUR_HUBSPOT_CLIENT_SECRET"
refreshToken = "YOUR_HUBSPOT_REFRESH_TOKEN"
```

## Run the Example

1. Execute the following command to run the example:

```bash
bal run
```

The program will execute the following operations:
- Create a new sign-up form with an email field
- Update the form to add first name, last name, phone number, and address fields
- Retrieve the updated form details
- Delete the created form

The output will show the form ID when created, update timestamp, creation timestamp, and deletion confirmation.