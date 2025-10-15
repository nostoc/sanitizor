# Sign up form

This example demonstrates how to create, update, retrieve, and delete sign-up forms using the Ballerina connector for HubSpot Marketing Forms. The system creates a basic email sign-up form, updates it to include additional fields like name, phone, and address, then retrieves and deletes the form.

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

2. The program will execute automatically and perform the following operations:
   - Create a basic sign-up form with an email field
   - Update the form to add first name, last name, phone number, and address fields
   - Retrieve the updated form details
   - Delete the form

   You should see output similar to:
   ```
   Form is created with ID: [FORM_ID]
   Form is updated at [TIMESTAMP]
   Form is created at [TIMESTAMP]
   [FORM_ID] Form is deleted at [TIMESTAMP]
   ```