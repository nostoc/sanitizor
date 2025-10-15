# Contact Us Form integration

This use case demonstrates how the HubSpot Marketing Forms Connector can be utilized to manage and optimize customer engagement through dynamic 'Contact Us' forms. The API facilitates seamless creation, updating, and deletion of forms while enabling retrieval of essential metadata, such as creation dates. By leveraging this integration, businesses can streamline customer interactions, ensure accurate data collection, and maintain an organized repository of customer inquiries.

## Prerequisites

### 1. Setup Hubspot account

Refer to the `Setup guide` in `README.md` file to set up your HubSpot account, if you do not have one.

### 2. Configuration

Update your HubSpot account related configurations in the `Config.toml` file in the example root directory:

```toml
clientId = ''
clientSecret = ''
refreshToken = ''
```

## Run the example

Execute the following command to run the example:

```ballerina
bal run
```