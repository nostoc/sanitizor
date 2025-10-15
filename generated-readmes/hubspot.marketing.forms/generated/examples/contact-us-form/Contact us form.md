# Contact Us Form

This example demonstrates how to create, update, retrieve, and delete contact forms using the Ballerina connector for HubSpot Marketing Forms. The system creates a contact form with email field, updates it to include additional fields like first name, last name, phone number, and message, then retrieves the form details before finally deleting it.

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

2. The application will execute the following operations:
   - Create a new contact form with an email field
   - Update the form to add first name, last name, phone number, and message fields
   - Retrieve the updated form details
   - Delete the created form