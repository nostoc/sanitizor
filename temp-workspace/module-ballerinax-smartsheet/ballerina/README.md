# smartsheet Ballerina Connector

# Overview

The Smartsheet connector for Ballerina provides seamless integration with the Smartsheet API, enabling developers to programmatically interact with Smartsheet's collaborative work management platform. This connector allows you to automate workflows, manage sheets, reports, and dashboards, and integrate Smartsheet functionality directly into your Ballerina applications.

## Key Features

- **Sheet Management**: Create, update, delete, and manipulate sheets with full CRUD operations
- **Collaboration Tools**: Manage discussions, comments, attachments, and sharing permissions
- **Workspace Operations**: Handle workspaces, folders, and organizational structure
- **Report & Dashboard Management**: Create and manage reports and dashboards for data visualization
- **User & Group Administration**: Manage users, groups, and access permissions
- **Automation**: Work with automation rules and update requests
- **Template Support**: Create sheets from templates and manage template libraries
- **File Operations**: Handle attachments, proofs, and file versioning
- **Real-time Updates**: Manage webhooks and event streams for real-time notifications
- **Publishing & Sharing**: Control sheet publishing and sharing capabilities

## Service Integration

This connector integrates with the **Smartsheet REST API**, providing access to Smartsheet's comprehensive work management and collaboration platform. It supports OAuth 2.0 authentication and includes comprehensive error handling for robust application development.

## Main Use Cases

- **Project Management**: Automate project task tracking, resource allocation, and timeline management
- **Data Synchronization**: Sync data between Smartsheet and other business systems
- **Reporting Automation**: Generate and distribute automated reports and dashboards
- **Workflow Integration**: Integrate Smartsheet into existing business workflows and processes
- **Collaborative Applications**: Build applications that leverage Smartsheet's collaboration features
- **Resource Management**: Automate resource planning and capacity management workflows

## Setup Guide

# Setup Guide

## Prerequisites

Before using the Smartsheet connector in your Ballerina application, complete the following:

- Download and install [Ballerina Swan Lake](https://ballerina.io/) version 2201.8.0 or later
- Obtain API credentials from [Smartsheet Developer Portal](https://developers.smartsheet.com/)

## Installation

### Step 1: Create a Ballerina Project

```bash
bal new smartsheet_integration
cd smartsheet_integration
```

### Step 2: Install the Connector

Add the Smartsheet connector to your project by updating the `Ballerina.toml` file or using the `bal add` command.

#### Option 1: Using `bal add` command

```bash
bal add smartsheet
```

#### Option 2: Manual addition to `Ballerina.toml`

```toml
[package]
org = "your_org"
name = "smartsheet_integration"
version = "0.1.0"

[[dependency]]
org = "ballerinax"
name = "smartsheet"
version = "1.0.0"
```

## Configuration

### Step 1: Obtain Smartsheet API Credentials

1. Log in to the [Smartsheet Developer Portal](https://developers.smartsheet.com/)
2. Navigate to "My Apps" and create a new app
3. Generate an API access token or set up OAuth 2.0 credentials
4. Note down your credentials for configuration

### Step 2: Configure Connection

Create a `Config.toml` file in your project root directory:

#### For API Token Authentication

```toml
[smartsheet]
token = "YOUR_SMARTSHEET_API_TOKEN"
```

#### For OAuth 2.0 Authentication

```toml
[smartsheet.oauth]
clientId = "YOUR_CLIENT_ID"
clientSecret = "YOUR_CLIENT_SECRET"
refreshToken = "YOUR_REFRESH_TOKEN"
```

### Step 3: Configure the Client

Create a Ballerina file (e.g., `main.bal`) and configure the client:

#### Using API Token

```ballerina
import ballerinax/smartsheet;

configurable string token = ?;

public function main() returns error? {
    smartsheet:ConnectionConfig config = {
        auth: {
            token: token
        }
    };
    
    smartsheet:Client smartsheetClient = check new (config);
    
    // Your implementation here
}
```

#### Using OAuth 2.0

```ballerina
import ballerinax/smartsheet;

configurable string clientId = ?;
configurable string clientSecret = ?;
configurable string refreshToken = ?;

public function main() returns error? {
    smartsheet:OAuth2RefreshTokenGrantConfig oauth2Config = {
        clientId: clientId,
        clientSecret: clientSecret,
        refreshToken: refreshToken
    };
    
    smartsheet:ConnectionConfig config = {
        auth: oauth2Config
    };
    
    smartsheet:Client smartsheetClient = check new (config);
    
    // Your implementation here
}
```

## Authentication Setup

### API Token Authentication (Recommended for Development)

1. In Smartsheet, go to **Account** > **Apps & Integrations**
2. Click **API Access**
3. Generate a new access token
4. Copy the token and add it to your `Config.toml` file

### OAuth 2.0 Authentication (Recommended for Production)

1. Register your application in the Smartsheet Developer Portal
2. Configure redirect URIs and scopes
3. Implement the OAuth 2.0 flow to obtain access and refresh tokens
4. Use the refresh token in your configuration

## Project Structure

Organize your Ballerina project as follows:

```
smartsheet_integration/
├── Ballerina.toml
├── Config.toml
├── main.bal
├── modules/
│   ├── sheets/
│   │   └── sheets.bal
│   ├── reports/
│   │   └── reports.bal
│   └── workspaces/
│       └── workspaces.bal
├── tests/
│   └── main_test.bal
└── resources/
    └── sample_data.json
```

### Sample Module Structure

Create separate modules for different Smartsheet functionalities:

#### `modules/sheets/sheets.bal`
```ballerina
import ballerinax/smartsheet;

public function createSheet(smartsheet:Client client, smartsheet:SheetCreate sheetData) 
    returns smartsheet:SheetCreated|error {
    return client->createSheet(sheetData);
}

public function getSheet(smartsheet:Client client, string sheetId) 
    returns smartsheet:Sheet|error {
    return client->getSheet(sheetId);
}
```

#### `modules/workspaces/workspaces.bal`
```ballerina
import ballerinax/smartsheet;

public function listWorkspaces(smartsheet:Client client) 
    returns smartsheet:WorkspaceListResponse|error {
    return client->listWorkspaces();
}

public function createWorkspace(smartsheet:Client client, smartsheet:WorkspaceCreateData workspaceData) 
    returns smartsheet:WorkspaceCreateResponse|error {
    return client->createWorkspace(workspaceData);
}
```

## Next Steps

1. Explore the [Smartsheet API documentation](https://smartsheet.redoc.ly/) for available operations
2. Check out the connector's API documentation for detailed method signatures
3. Implement error handling and logging for production use
4. Consider implementing retry mechanisms for API calls
5. Test your integration thoroughly before deployment

You are now ready to use the Smartsheet connector in your Ballerina application!

## Quick Start

# Quick Start

This guide helps you get started with the Ballerina Smartsheet connector, which allows you to interact with Smartsheet's API to manage sheets, workspaces, users, and more.

## Prerequisites

1. Ballerina 2201.8.0 or later
2. A Smartsheet account with API access
3. A Smartsheet API access token

## Step 1: Import the Connector

Add the Smartsheet connector to your `Ballerina.toml` file:

```toml
[package]
name = "smartsheet_example"
version = "0.1.0"

[[dependency]]
org = "ballerinax"
name = "smartsheet"
version = "1.0.0"
```

## Step 2: Initialize the Client

Create a new Ballerina file (e.g., `main.bal`) and initialize the Smartsheet client:

```ballerina
import ballerinax/smartsheet;
import ballerina/io;

public function main() returns error? {
    // Initialize the Smartsheet client with your API token
    smartsheet:ConnectionConfig config = {
        auth: {
            token: "YOUR_SMARTSHEET_API_TOKEN"
        }
    };
    
    smartsheet:Client smartsheetClient = check new (config);
    
    // Your Smartsheet operations go here
}
```

## Step 3: Basic Operations

### Example 1: List All Sheets

```ballerina
import ballerinax/smartsheet;
import ballerina/io;

public function main() returns error? {
    smartsheet:ConnectionConfig config = {
        auth: {
            token: "YOUR_SMARTSHEET_API_TOKEN"
        }
    };
    
    smartsheet:Client smartsheetClient = check new (config);
    
    // List all sheets accessible to the user
    smartsheet:SheetList|error sheets = smartsheetClient->listSheets();
    
    if sheets is smartsheet:SheetList {
        io:println("Found sheets:");
        foreach var sheet in sheets.data {
            io:println(string `- ${sheet.name} (ID: ${sheet.id})`);
        }
    } else {
        io:println("Error fetching sheets: ", sheets.message());
    }
}
```

### Example 2: Create a New Sheet

```ballerina
import ballerinax/smartsheet;
import ballerina/io;

public function main() returns error? {
    smartsheet:ConnectionConfig config = {
        auth: {
            token: "YOUR_SMARTSHEET_API_TOKEN"
        }
    };
    
    smartsheet:Client smartsheetClient = check new (config);
    
    // Create a new sheet with basic columns
    smartsheet:SheetToCreate newSheet = {
        name: "Project Task Tracker",
        columns: [
            {
                title: "Task Name",
                'type: "TEXT_NUMBER",
                primary: true
            },
            {
                title: "Assigned To",
                'type: "CONTACT_LIST"
            },
            {
                title: "Status",
                'type: "PICKLIST",
                options: ["Not Started", "In Progress", "Complete"]
            },
            {
                title: "Due Date",
                'type: "DATE"
            }
        ]
    };
    
    smartsheet:SheetCreated|error result = smartsheetClient->createSheet(newSheet);
    
    if result is smartsheet:SheetCreated {
        io:println(string `Sheet created successfully!`);
        io:println(string `Sheet ID: ${result.result?.id}`);
        io:println(string `Sheet Name: ${result.result?.name}`);
        io:println(string `Permalink: ${result.result?.permalink}`);
    } else {
        io:println("Error creating sheet: ", result.message());
    }
}
```

## Expected Output

### For listing sheets:
```
Found sheets:
- My Project Plan (ID: 1234567890)
- Budget Tracker (ID: 2345678901)
- Team Schedule (ID: 3456789012)
```

### For creating a sheet:
```
Sheet created successfully!
Sheet ID: 4567890123
Sheet Name: Project Task Tracker
Permalink: https://app.smartsheet.com/sheets/abc123def456
```

## Next Steps

Once you have the connector working, you can explore more advanced operations such as:

- Adding rows to sheets using `SheetAddRow` operations
- Managing workspaces with `WorkspaceCreate` and `WorkspaceUpdate`
- Setting up automations using `AutomationRule` types
- Managing user permissions with `ShareSheet` operations
- Creating reports and dashboards

For detailed API documentation and more examples, refer to the [Smartsheet API documentation](https://smartsheet.redoc.ly/).

## Error Handling

Always handle potential errors when working with external APIs:

```ballerina
smartsheet:SheetList|error sheets = smartsheetClient->listSheets();
if sheets is error {
    io:println("API Error: ", sheets.message());
    io:println("Error Details: ", sheets.detail().toString());
}
```

## Examples

# Examples

This section provides practical examples to help you get started with the Smartsheet Ballerina connector. Each example demonstrates key features and common use cases.

## Available Examples

### 1. Project Task Management
**File**: [`project_task_management.bal`](examples/project_task_management/project_task_management.bal)

This comprehensive example demonstrates how to build a project management solution using Smartsheet. It covers:

- **Sheet Operations**: Creating project sheets, updating sheet properties, and managing sheet permissions
- **Row Management**: Adding tasks as rows, updating task status, and bulk operations on multiple rows
- **Column Configuration**: Setting up project columns (task name, assignee, due date, status, priority)
- **Collaboration Features**: Adding comments to tasks, creating discussions, and managing team communication
- **File Attachments**: Uploading project documents and linking files to specific tasks
- **Automation**: Setting up automated workflows and update requests for task assignments
- **Reporting**: Generating project status reports and tracking progress metrics

**Key Learning Points**:
- Essential CRUD operations for sheets and rows
- Working with different column types and data validation
- Implementing team collaboration workflows
- Managing project timelines and dependencies
- Error handling and best practices

**Recommended For**: Beginners and intermediate users looking to understand core Smartsheet functionality through a real-world project management scenario.

## Getting Started

1. **Start Here**: Begin with the `project_task_management` example as it covers the most commonly used connector features
2. **Prerequisites**: Ensure you have valid Smartsheet API credentials and the necessary permissions
3. **Setup**: Follow the configuration steps in each example's README file
4. **Experimentation**: Modify the examples to match your specific use cases

## Running the Examples

```bash
# Navigate to the example directory
cd examples/project_task_management

# Run the example
bal run project_task_management.bal
```

Each example includes detailed comments explaining the code structure and API usage patterns to help you understand and adapt the implementations for your own projects.

## Issues and Contributions

If you encounter any issues or would like to contribute to this connector, please create an issue or pull request in the connector's repository.

## License

This project is licensed under the Apache License 2.0. See the LICENSE file for details.