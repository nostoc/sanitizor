# Examples

The "HubSpot Marketing Forms Connector" provides practical examples illustrating usage in various scenarios. Explore these examples, covering use cases like user registration, data management, and metadata tracking.

1. [Contact Us Form Integration](https://github.com/ballerina-platform/module-ballerinax-hubspot.marketing.forms/tree/main/examples/contact-us-form) - Build dynamic 'Contact Us' forms to handle customer inquiries efficiently, enabling seamless communication and accurate data collection.

2. [Sign Up Form Integration](https://github.com/ballerina-platform/module-ballerinax-hubspot.marketing.forms/tree/main/examples/sign-up-form) - Create, update, and manage user registration forms with customizable fields such as name, email, and consent checkboxes to streamline user onboarding.



## Prerequisites

### 1. Setup Hubspot account

Refer to the "Setup guide" in "README.md" file to set up your hubspot
account, if you do not have one.

### 2. Configuration

Update your HubSpot account related configurations in the "Config.toml" file in the example root directory:

```toml
clientId = ''
clientSecret = ''
refreshToken = ''
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

## Building the Examples with the Local Module

**Warning**: Due to the absence of support for reading local repositories for single Ballerina files, the Bala of the module is manually written to the central repository as a workaround. Consequently, the bash script may modify your local Ballerina repositories.

Execute the following commands to build all the examples against the changes you have made to the module locally:

* To build all the examples:

    ```bash
    ./build.sh build
    ```

* To run all the examples:

    ```bash
    ./build.sh run
    ```