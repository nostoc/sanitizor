# {{CONNECTOR_NAME}} Tests

This directory contains the test suite for the {{CONNECTOR_NAME}} Ballerina connector.

## Testing Approach

{{AI_GENERATED_TESTING_APPROACH}}

## Test Scenarios

{{AI_GENERATED_TEST_SCENARIOS}}

## Running Tests

To run all tests:
```bash
bal test
```

To run tests with coverage:
```bash
bal test --code-coverage
```

## Mock Service

The tests use a mock service that simulates the actual API endpoints. This allows tests to run independently of the external service and provides predictable responses for testing various scenarios.

## Test Configuration

Make sure to configure any required environment variables or configuration files before running the tests. Check the test files for specific requirements.

## Contributing to Tests

When adding new features, please ensure you also add corresponding test cases. Follow the existing test patterns and ensure good coverage of both success and failure scenarios.