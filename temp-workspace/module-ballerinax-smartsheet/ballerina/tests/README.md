# smartsheet Tests

This directory contains the test suite for the smartsheet Ballerina connector.

## Testing Approach

# Testing Approach

This document outlines the testing strategy and approach for the Smartsheet Ballerina connector (version 1.0.0).

## Types of Tests

### 1. Unit Tests
Unit tests focus on testing individual functions and methods in isolation. These tests validate:
- Data transformation and mapping logic
- Request/response payload construction
- Error handling mechanisms
- Type conversions and validations

```ballerina
@test:Config {}
function testWorkspaceCreateData() {
    WorkspaceCreateData workspaceData = {
        name: "Test Workspace",
        description: "A test workspace for validation"
    };
    test:assertEquals(workspaceData.name, "Test Workspace");
    test:assertNotEquals(workspaceData.description, null);
}
```

### 2. Integration Tests
Integration tests validate the connector's interaction with the Smartsheet API endpoints. These tests cover:
- Complete request-response cycles
- Authentication and authorization flows
- API endpoint connectivity
- Data persistence and retrieval operations

```ballerina
@test:Config {}
function testCreateSheet() returns error? {
    SmartsheetClient smartsheetClient = check new(config);
    SheetToCreate sheetData = {
        name: "Integration Test Sheet",
        columns: [
            {name: "Task", type: "TEXT_NUMBER", primary: true},
            {name: "Status", type: "PICKLIST", options: ["Not Started", "In Progress", "Complete"]}
        ]
    };
    
    SheetCreated response = check smartsheetClient->createSheet(sheetData);
    test:assertTrue(response.id > 0);
    test:assertEquals(response.name, "Integration Test Sheet");
}
```

### 3. Mock Service Tests
Mock service tests simulate Smartsheet API responses to test various scenarios without making actual API calls.

## Mock Service Usage and Approach

### Mock Service Setup
The test suite uses Ballerina's built-in HTTP service mocking capabilities to simulate Smartsheet API responses:

```ballerina
import ballerina/test;
import ballerina/http;

http:Client mockClient = check new("http://localhost:9090");

service /smartsheet on new http:Listener(9090) {
    
    resource function post sheets(http:Caller caller, http:Request req) returns error? {
        json mockResponse = {
            "id": 12345,
            "name": "Mock Sheet",
            "permalink": "https://app.smartsheet.com/sheets/mock",
            "createdAt": "2024-01-01T00:00:00Z",
            "modifiedAt": "2024-01-01T00:00:00Z"
        };
        check caller->respond(mockResponse);
    }
    
    resource function get sheets/[int sheetId](http:Caller caller, http:Request req) returns error? {
        json mockSheet = {
            "id": sheetId,
            "name": "Mock Retrieved Sheet",
            "columns": [],
            "rows": []
        };
        check caller->respond(mockSheet);
    }
}
```

### Mock Response Scenarios
The mock service covers various test scenarios:
- **Success responses** - Valid API responses with expected data structures
- **Error responses** - HTTP error codes (400, 401, 403, 404, 500) with appropriate error messages
- **Edge cases** - Empty responses, large datasets, special characters
- **Rate limiting** - Simulated rate limit responses (429 status code)

```ballerina
@test:Config {}
function testErrorHandling() returns error? {
    // Test 404 Not Found scenario
    SheetResponse|error response = smartsheetClient->getSheet(999999);
    test:assertTrue(response is error);
    
    if response is error {
        test:assertTrue(response.message().includes("Sheet not found"));
    }
}
```

## Test Data Management

### Test Data Structure
Test data is organized using structured approaches:

```ballerina
// Test configuration
configurable string accessToken = ?;
configurable string baseUrl = "https://api.smartsheet.com/2.0";

// Test data constants
const string TEST_SHEET_NAME = "Ballerina Test Sheet";
const string TEST_WORKSPACE_NAME = "Ballerina Test Workspace";
const int MOCK_SHEET_ID = 12345;
const int MOCK_WORKSPACE_ID = 67890;

// Test data builders
function createTestSheetData() returns SheetToCreate {
    return {
        name: TEST_SHEET_NAME,
        columns: [
            {name: "Primary Column", type: "TEXT_NUMBER", primary: true},
            {name: "Status", type: "PICKLIST", options: ["New", "In Progress", "Complete"]},
            {name: "Priority", type: "PICKLIST", options: ["High", "Medium", "Low"]}
        ]
    };
}
```

### Test Environment Configuration
Configuration management for different test environments:

```ballerina
// Config.toml for test environment
[ballerina.test]
accessToken = "${SMARTSHEET_ACCESS_TOKEN}"
baseUrl = "${SMARTSHEET_BASE_URL}"
testSheetId = "${TEST_SHEET_ID}"
testWorkspaceId = "${TEST_WORKSPACE_ID}"
```

## How to Run the Tests

### Prerequisites
1. **Ballerina Environment**: Ensure Ballerina Swan Lake is installed
2. **Test Configuration**: Set up the required configuration values
3. **API Access**: Valid Smartsheet API access token for integration tests

### Running All Tests
```bash
# Run all tests in the package
bal test

# Run tests with coverage report
bal test --code-coverage

# Run tests with specific test groups
bal test --groups unit
bal test --groups integration
bal test --groups mock
```

### Running Specific Test Files
```bash
# Run specific test file
bal test tests/sheet_operations_test.bal

# Run with verbose output
bal test --verbose

# Run tests and generate reports
bal test --test-report --coverage-report
```

### Test Configuration Setup
```bash
# Set environment variables
export SMARTSHEET_ACCESS_TOKEN="your_access_token_here"
export SMARTSHEET_BASE_URL="https://api.smartsheet.com/2.0"

# Or use Config.toml
echo '[test]
accessToken = "your_access_token"
baseUrl = "https://api.smartsheet.com/2.0"' > Config.toml
```

## Test Validation Coverage

### API Operations Testing
The test suite validates the following Smartsheet operations:

1. **Sheet Operations**
   - Create, read, update, delete sheets
   - Sheet sharing and permissions
   - Sheet publishing and export

2. **Workspace Operations**
   - Workspace creation and management
   - Workspace sharing and member management
   - Workspace folder operations

3. **Row and Column Operations**
   - Adding, updating, deleting rows
   - Column management and formatting
   - Cell value updates and validations

4. **Attachment Operations**
   - File attachments to sheets and rows
   - Attachment versioning
   - Attachment metadata retrieval

5. **User and Group Management**
   - User profile operations
   - Group creation and member management
   - Permission and access level validations

### Data Type Validation
Tests ensure proper handling of Smartsheet-specific data types:

```ballerina
@test:Config {}
function testCellObjectTypes() {
    // Test different cell value types
    CellObjectForRows textCell = {columnId: 123, value: "Sample Text"};
    CellObjectForRows numberCell = {columnId: 124, value: 42.5};
    CellObjectForRows dateCell = {columnId: 125, value: "2024-01-01"};
    CellObjectForRows checkboxCell = {columnId: 126, value: true};
    
    test:assertEquals(textCell.value, "Sample Text");
    test:assertEquals(numberCell.value, 42.5);
    test:assertTrue(checkboxCell.value is boolean);
}
```

### Error Handling Validation
Comprehensive error scenario testing:

```ballerina
@test:Config {groups: ["error-handling"]}
function testRateLimitHandling() returns error? {
    // Test rate limiting scenario
    // This would typically use mock service to simulate 429 responses
    error? result = ();
    int attempts = 0;
    
    while attempts < 5 {
        SheetResponse|error response = smartsheetClient->getSheet(MOCK_SHEET_ID);
        if response is error && response.message().includes("Rate limit") {
            // Validate proper rate limit handling
            test:assertTrue(true, "Rate limit properly detected");
            break;
        }
        attempts += 1;
    }
}
```

### Authentication and Authorization Testing
```ballerina
@test:Config {groups: ["auth"]}
function testInvalidToken() {
    ConnectionConfig invalidConfig = {
        auth: {
            token: "invalid_token"
        }
    };
    
    SmartsheetClient|error client = new(invalidConfig);
    test:assertTrue(client is SmartsheetClient);
    
    if client is SmartsheetClient {
        SheetResponse|error response = client->getSheet(MOCK_SHEET_ID);
        test:assertTrue(response is error, "Should fail with invalid token");
    }
}
```

The testing approach ensures comprehensive validation of the Smartsheet connector's functionality, reliability, and error handling capabilities while following Ballerina testing best practices and conventions.

## Test Scenarios

# Test Scenarios

This document outlines comprehensive test scenarios for the Smartsheet connector v1.0.0, covering various functionalities and edge cases to ensure robust integration with the Smartsheet API.

## 1. Authentication & Authorization Tests

### 1.1 OAuth2 Authentication
- **Valid OAuth2 Token Flow**: Test successful authentication with valid OAuth2 credentials
- **Token Refresh**: Validate automatic token refresh when access token expires
- **Invalid Credentials**: Verify proper error handling for invalid client ID/secret
- **Expired Token Handling**: Test behavior when refresh token is expired
- **Token Revocation**: Test `AccesstokenRevoke` functionality and subsequent API calls

### 1.2 Authorization Tests
- **Access Level Validation**: Test different access levels (read-only, read-write, admin)
- **Workspace Permissions**: Validate user permissions across different workspaces
- **Sheet-level Permissions**: Test access control for individual sheets
- **Share Permissions**: Verify sharing permissions and access restrictions

## 2. Sheet Management Tests

### 2.1 Sheet CRUD Operations
- **Create Sheet**: Test successful sheet creation with valid data using `SheetCreate`
- **Get Sheet**: Retrieve sheet details with various query parameters
- **Update Sheet**: Modify sheet properties and validate changes
- **Delete Sheet**: Test sheet deletion and proper cleanup
- **Sheet Listing**: Retrieve lists of sheets with pagination and filtering

### 2.2 Sheet Operations
- **Copy Sheet**: Test sheet copying within and across workspaces
- **Move Sheet**: Validate sheet movement between folders/workspaces
- **Export Sheet**: Test various export formats (PDF, Excel, CSV)
- **Import Sheet**: Validate sheet import functionality
- **Sheet Backup**: Test sheet backup creation and restoration

### 2.3 Sheet Publishing
- **Publish Sheet**: Test sheet publishing with different settings
- **Update Publish Settings**: Modify publishing configuration
- **Unpublish Sheet**: Remove public access to sheets
- **Get Publish Status**: Retrieve current publishing information

## 3. Row Management Tests

### 3.1 Row Operations
- **Add Rows**: Test row addition with valid data using `AddRowsObject`
- **Update Rows**: Modify existing row data and validate changes
- **Delete Rows**: Remove rows and verify proper deletion
- **Get Rows**: Retrieve row data with filtering and sorting
- **Move Rows**: Test row movement within and between sheets

### 3.2 Row Email and Notifications
- **Send Row via Email**: Test `RowEmail` functionality with various recipients
- **Row Notifications**: Validate notification settings and delivery
- **Update Request**: Test creation and management of update requests

## 4. Column Management Tests

### 4.1 Column CRUD Operations
- **Add Columns**: Test column creation with different data types
- **Update Columns**: Modify column properties and formatting
- **Delete Columns**: Remove columns and validate data integrity
- **Get Columns**: Retrieve column information and metadata

### 4.2 Column Types and Validation
- **Data Type Validation**: Test various column types (text, number, date, checkbox)
- **Formula Columns**: Validate formula creation and calculation
- **System Columns**: Test system column behavior and restrictions
- **Column Formatting**: Verify formatting options and display

## 5. Workspace and Folder Management Tests

### 5.1 Workspace Operations
- **Create Workspace**: Test workspace creation using `WorkspaceCreate`
- **Update Workspace**: Modify workspace properties
- **Delete Workspace**: Remove workspace and contents
- **List Workspaces**: Retrieve workspace listings with permissions

### 5.2 Folder Management
- **Create Folders**: Test folder creation in workspaces
- **Move Folders**: Validate folder movement operations
- **Copy Folders**: Test folder duplication functionality
- **Folder Hierarchy**: Verify nested folder structures

## 6. Sharing and Permissions Tests

### 6.1 Share Management
- **Share Sheet**: Test sheet sharing with different permission levels
- **Share Workspace**: Validate workspace sharing functionality
- **Remove Shares**: Test share removal and access revocation
- **Update Share Permissions**: Modify existing share permissions

### 6.2 Group Management
- **Create Groups**: Test group creation using `GroupCreate`
- **Add Members**: Add users to groups with proper validation
- **Remove Members**: Remove users from groups
- **Group Permissions**: Test group-based permission inheritance

## 7. Attachment and Proof Management Tests

### 7.1 Attachment Operations
- **Upload Attachments**: Test file upload to sheets, rows, and comments
- **Download Attachments**: Retrieve attachment data and metadata
- **Delete Attachments**: Remove attachments and verify cleanup
- **Attachment Versions**: Test version management for attachments

### 7.2 Proofing Workflow
- **Create Proofs**: Test proof creation using `ProofCreateResponse`
- **Proof Requests**: Validate proof request workflow
- **Proof Comments**: Test commenting on proofs
- **Proof Approval**: Test approval/rejection workflow

## 8. Automation and Webhooks Tests

### 8.1 Automation Rules
- **Create Rules**: Test automation rule creation
- **Update Rules**: Modify existing automation rules
- **Delete Rules**: Remove automation rules
- **Rule Execution**: Validate rule triggering and actions

### 8.2 Webhook Management
- **Create Webhooks**: Test webhook registration using `CreateWebhookRequest`
- **Update Webhooks**: Modify webhook configuration
- **Delete Webhooks**: Remove webhook subscriptions
- **Webhook Delivery**: Validate event delivery and payload format

## 9. Reporting and Dashboard Tests

### 9.1 Report Operations
- **Create Reports**: Test report creation from sheets
- **Update Reports**: Modify report configuration
- **Export Reports**: Test report export in various formats
- **Report Sharing**: Validate report sharing functionality

### 9.2 Dashboard Management
- **Create Dashboards**: Test dashboard creation using `DashboardCreate`
- **Update Dashboards**: Modify dashboard widgets and layout
- **Dashboard Sharing**: Test dashboard sharing permissions
- **Dashboard Export**: Validate dashboard export functionality

## 10. User and Account Management Tests

### 10.1 User Operations
- **Get User Profile**: Retrieve current user information
- **Update User**: Modify user profile data
- **User Invitations**: Test user invitation workflow
- **Deactivate Users**: Test user deactivation process

### 10.2 Account Management
- **Account Information**: Retrieve account details and limits
- **Bulk Operations**: Test bulk user and sheet operations
- **Account Reports**: Generate usage and access reports

## 11. Error Handling and Edge Cases

### 11.1 API Error Scenarios
- **Rate Limiting**: Test behavior when API rate limits are exceeded
- **Invalid Data**: Validate error responses for malformed requests
- **Resource Not Found**: Test 404 error handling for non-existent resources
- **Permission Denied**: Validate 403 error responses for unauthorized access

### 11.2 Data Validation
- **Field Validation**: Test validation for required fields and data types
- **Size Limits**: Validate file size and data limits
- **Character Encoding**: Test Unicode and special character handling
- **Date/Time Formats**: Validate various date and time format handling

## 12. Performance and Reliability Tests

### 12.1 Performance Tests
- **Large Dataset Handling**: Test performance with large sheets and datasets
- **Concurrent Operations**: Validate concurrent API calls and race conditions
- **Pagination**: Test large result set pagination
- **Bulk Operations**: Performance testing for bulk data operations

### 12.2 Reliability Tests
- **Network Resilience**: Test behavior during network interruptions
- **Timeout Handling**: Validate timeout scenarios and retry logic
- **Data Consistency**: Ensure data integrity across operations
- **Memory Management**: Test memory usage with large operations

## 13. Integration Scenarios

### 13.1 Cross-Feature Integration
- **Sheet-to-Report Workflow**: Test complete workflow from sheet creation to reporting
- **Collaboration Workflow**: Test multi-user collaboration scenarios
- **Automation Integration**: Test integration between automation rules and other features
- **Template Usage**: Test creating sheets from templates and template management

### 13.2 Real-world Scenarios
- **Project Management**: Test typical project management workflows
- **Task Tracking**: Validate task assignment and tracking scenarios
- **Resource Management**: Test resource allocation and management workflows
- **Approval Processes**: Test multi-stage approval workflows

Each test scenario should include:
- **Preconditions**: Required setup and initial state
- **Test Steps**: Detailed steps to execute the test
- **Expected Results**: Clear success criteria
- **Error Conditions**: Expected error messages and codes
- **Cleanup**: Steps to clean up test data and restore initial state

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