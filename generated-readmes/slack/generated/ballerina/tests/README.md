# Running Tests

## Prerequisites
You need an API Access token from slack developer account.

To do this, refer to [Ballerina slack Connector](`https://github.com/ballerina-platform/module-ballerinax-slack/blob/main/ballerina/README.md`).

## Running Tests

There are two test environments for running the slack connector tests. The default test environment is the mock server for slack API. The other test environment is the actual slack API.

You can run the tests in either of these environments and each has its own compatible set of tests.

 Test Groups | Environment
-------------|---------------------------------------------------
 mock_tests  | Mock server for slack API (Default Environment)
 live_tests  | slack API

## Running Tests in the Mock Server

To execute the tests on the mock server, ensure that the `IS_LIVE_SERVER` environment variable is either set to `false` or unset before initiating the tests.

This environment variable can be configured within the `Config.toml` file located in the tests directory or specified as an environmental variable.

#### Using a Config.toml File

Create a `Config.toml` file in the tests directory and the following content:

```toml
isLiveServer = false
```

#### Using Environment Variables

Alternatively, you can set your authentication credentials as environment variables:
If you are using linux or mac, you can use following method:
```bash
   export IS_LIVE_SERVER=false
```
If you are using Windows you can use following method:
```bash
   setx IS_LIVE_SERVER false
```
Then, run the following command to run the tests:

```bash
   ./gradlew clean test
```

## Running Tests Against slack Live API

#### Using a Config.toml File

Create a `Config.toml` file in the tests directory and add your authentication credentials:

```toml
   isLiveServer = true
   token = "<your-slack-access-token>"
```

#### Using Environment Variables

Alternatively, you can set your authentication credentials as environment variables:
If you are using linux or mac, you can use following method:
```bash
   export IS_LIVE_SERVER=true
   export SLACK_TOKEN="<your-slack-access-token>"
```

If you are using Windows you can use following method:
```bash
   setx IS_LIVE_SERVER true
   setx SLACK_TOKEN <your-slack-access-token>
```
Then, run the following command to run the tests:

```bash
   ./gradlew clean test
```