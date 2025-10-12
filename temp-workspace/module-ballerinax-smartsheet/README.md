# smartsheet Ballerina Connector

# Smartsheet Connector

The Smartsheet connector for Ballerina provides seamless integration with the Smartsheet platform, enabling developers to build powerful work management and collaboration applications. This connector offers comprehensive access to Smartsheet's rich API, allowing you to programmatically manage sheets, reports, dashboards, workspaces, and collaborate with team members.

## 🎯 Overview

Smartsheet is a leading work execution platform that enables organizations to plan, capture, manage, automate, and report on work at scale. This Ballerina connector empowers developers to integrate Smartsheet's capabilities directly into their applications, automating workflows and creating custom solutions for project management, resource planning, and team collaboration.

## ✨ Key Features

- **Complete Sheet Management** - Create, update, delete, and manipulate sheets with full CRUD operations
- **Advanced Reporting** - Generate and manage reports with filtering, sorting, and data aggregation
- **Dashboard Integration** - Build and customize dashboards for data visualization and insights  
- **Workspace Collaboration** - Manage workspaces, folders, and team permissions
- **Real-time Updates** - Handle webhooks and events for real-time data synchronization
- **File Attachments** - Upload, download, and manage file attachments and proofs
- **User Management** - Handle user accounts, groups, and access permissions
- **Automation Rules** - Create and manage workflow automations
- **Template Support** - Work with sheet templates for standardized processes
- **Cross-sheet References** - Manage data relationships across multiple sheets

## 👥 Who Should Use This Connector

- **Enterprise Developers** building custom project management solutions
- **System Integrators** connecting Smartsheet with existing business systems
- **Automation Engineers** creating workflow automation between Smartsheet and other platforms
- **Data Engineers** synchronizing data between Smartsheet and databases/analytics tools
- **Application Developers** embedding Smartsheet functionality into web and mobile applications

## 🏗️ Architecture Overview

```
┌─────────────────────────┐    ┌──────────────────────┐    ┌─────────────────────────┐
│   Ballerina Application │    │  Smartsheet Connector│    │    Smartsheet API      │
│                         │    │                      │    │                         │
│  ┌─────────────────────┐│    │ ┌──────────────────┐ │    │ ┌─────────────────────┐ │
│  │   Business Logic    ││────┤ │   HTTP Client    │ ├────┤ │   REST Endpoints    │ │
│  └─────────────────────┘│    │ └──────────────────┘ │    │ └─────────────────────┘ │
│                         │    │                      │    │                         │
│  ┌─────────────────────┐│    │ ┌──────────────────┐ │    │ ┌─────────────────────┐ │
│  │   Data Processing   ││────┤ │  Type Definitions│ ├────┤ │   Data Models       │ │
│  └─────────────────────┘│    │ └──────────────────┘ │    │ └─────────────────────┘ │
│                         │    │                      │    │                         │
│  ┌─────────────────────┐│    │ ┌──────────────────┐ │    │ ┌─────────────────────┐ │
│  │   Error Handling    ││────┤ │  OAuth2 & Auth   │ ├────┤ │   Authentication    │ │
│  └─────────────────────┘│    │ └──────────────────┘ │    │ └─────────────────────┘ │
└─────────────────────────┘    └──────────────────────┘    └─────────────────────────┘
```

The connector acts as a bridge between your Ballerina application and Smartsheet's REST API, providing:
- **Type-safe operations** with comprehensive data models
- **OAuth2 authentication** for secure API access  
- **Error handling** with detailed error responses
- **Structured data exchange** using Ballerina's native types

## 🚀 Quick Start

Get started with basic sheet operations:

```ballerina
import ballerina/smartsheet;

// Initialize the connector
smartsheet:Client smartsheetClient = new({
    auth: {
        token: "your_access_token"
    }
});

// Create a new sheet
smartsheet:SheetCreate newSheet = {
    name: "Project Tasks",
    columns: [
        {name: "Task Name", type: "TEXT_NUMBER", primary: true},
        {name: "Assigned To", type: "CONTACT_LIST"},
        {name: "Due Date", type: "DATE"},
        {name: "Status", type: "PICKLIST"}
    ]
};

smartsheet:SheetResponse|error result = smartsheetClient->createSheet(newSheet);
```

## 📚 Documentation Sections

- **[Authentication Setup](docs/auth.md)** - Configure OAuth2 and API tokens
- **[Sheet Operations](docs/sheets.md)** - Complete guide to sheet management
- **[Report Management](docs/reports.md)** - Creating and managing reports
- **[Dashboard Integration](docs/dashboards.md)** - Building interactive dashboards  
- **[Workspace Collaboration](docs/workspaces.md)** - Managing workspaces and permissions
- **[Webhook Integration](docs/webhooks.md)** - Real-time event handling
- **[Error Handling](docs/errors.md)** - Best practices for error management
- **[Examples](examples/)** - Practical implementation examples

---

**Version:** 1.0.0 | **Compatibility:** Ballerina 2201.x and above

Ready to streamline your work management processes? Start building with the Smartsheet connector today! 🚀

## Usage

# Usage

## Installation and Setup

Add the Smartsheet connector to your Ballerina project:

```bash
bal add smartsheet
```

### Configuration

Create a Smartsheet client with your API token:

```ballerina
import ballerina/smartsheet;

configurable string smartsheetToken = ?;

smartsheet:Client smartsheetClient = check new({
    auth: {
        token: smartsheetToken
    }
});
```

You can obtain your API token from your Smartsheet account settings under "Personal Settings" > "API Access".

## Basic Usage Patterns

### Working with Sheets

```ballerina
// List all sheets
smartsheet:SheetList sheets = check smartsheetClient->listSheets();

// Get a specific sheet
smartsheet:Sheet sheet = check smartsheetClient->getSheet(sheetId);

// Create a new sheet
smartsheet:SheetCreate newSheet = {
    name: "Project Tasks",
    columns: [
        {name: "Task Name", type: "TEXT_NUMBER", primary: true},
        {name: "Status", type: "PICKLIST", options: ["Not Started", "In Progress", "Complete"]}
    ]
};
smartsheet:SheetCreated createdSheet = check smartsheetClient->createSheet(newSheet);
```

### Managing Rows and Data

```ballerina
// Add rows to a sheet
smartsheet:RowCreateData[] newRows = [
    {
        cells: [
            {columnId: columnId1, value: "Task 1"},
            {columnId: columnId2, value: "In Progress"}
        ]
    }
];
smartsheet:RowCreateResponse rowResponse = check smartsheetClient->addRows(sheetId, newRows);

// Update existing rows
smartsheet:UpdateRowsObject updateData = {
    id: rowId,
    cells: [{columnId: columnId2, value: "Complete"}]
};
check smartsheetClient->updateRows(sheetId, [updateData]);
```

### Working with Workspaces and Folders

```ballerina
// List workspaces
smartsheet:WorkspaceListResponse workspaces = check smartsheetClient->listWorkspaces();

// Create a folder
smartsheet:FolderCreateData folderData = {
    name: "Q1 Projects"
};
smartsheet:FolderCreateResponse folder = check smartsheetClient->createFolder(folderData);
```

## Key Configuration Options

### Authentication
- **API Token**: Personal access token for API authentication
- **OAuth2**: For applications requiring user authorization

### Client Configuration
```ballerina
smartsheet:ConnectionConfig config = {
    auth: {
        token: smartsheetToken
    },
    timeout: 30, // Request timeout in seconds
    retryConfig: {
        count: 3,
        interval: 2
    }
};
```

## Common Use Cases

### Project Management Dashboard

```ballerina
// Create a project tracking sheet
smartsheet:SheetCreate projectSheet = {
    name: "Project Dashboard",
    columns: [
        {name: "Project Name", type: "TEXT_NUMBER", primary: true},
        {name: "Owner", type: "CONTACT_LIST"},
        {name: "Status", type: "PICKLIST", options: ["Planning", "Active", "On Hold", "Complete"]},
        {name: "Due Date", type: "DATE"}
    ]
};

smartsheet:SheetCreated sheet = check smartsheetClient->createSheet(projectSheet);
```

### Automated Reporting

```ballerina
// Generate and share reports
smartsheet:ReportCreate reportConfig = {
    name: "Weekly Status Report",
    sourceSheets: [sheetId1, sheetId2]
};

smartsheet:Report report = check smartsheetClient->createReport(reportConfig);

// Share the report
smartsheet:ShareCreateData shareData = {
    email: "manager@company.com",
    accessLevel: "VIEWER"
};
check smartsheetClient->shareReport(report.id, shareData);
```

### Bulk Data Operations

```ballerina
// Import data from external sources
smartsheet:RowCreateData[] bulkRows = [];
foreach var dataItem in externalData {
    bulkRows.push({
        cells: [
            {columnId: nameColumnId, value: dataItem.name},
            {columnId: statusColumnId, value: dataItem.status}
        ]
    });
}

smartsheet:RowCreateResponse bulkResult = check smartsheetClient->addRows(sheetId, bulkRows);
```

### Webhook Integration

```ballerina
// Set up webhooks for real-time updates
smartsheet:CreateWebhookRequest webhookConfig = {
    name: "Sheet Updates",
    callbackUrl: "https://myapp.com/webhook",
    scope: "sheet",
    scopeObjectId: sheetId,
    events: ["*.*"]
};

smartsheet:WebhookResponse webhook = check smartsheetClient->createWebhook(webhookConfig);
```

## Error Handling

```ballerina
import ballerina/http;

smartsheet:Sheet|error result = smartsheetClient->getSheet(sheetId);
if result is error {
    if result is http:ClientError {
        // Handle HTTP errors (rate limits, authentication, etc.)
        log:printError("API Error", result);
    } else {
        // Handle other errors
        log:printError("Unexpected error", result);
    }
} else {
    // Process the sheet data
    log:printInfo("Sheet retrieved: " + result.name);
}
```

## Additional Resources

- [Ballerina Smartsheet Connector Examples](examples/)
- [Smartsheet API Documentation](https://smartsheet.redoc.ly/)
- [Authentication Guide](docs/authentication.md)
- [Best Practices](docs/best-practices.md)
- [Rate Limiting and Error Handling](docs/error-handling.md)

For more detailed examples and advanced usage patterns, refer to the [examples directory](examples/) in this repository.

## Documentation

- **[Connector Documentation](ballerina/README.md)** - Detailed setup, configuration, and API reference
- **[Examples](examples/README.md)** - Practical examples and use cases
- **[Tests](ballerina/tests/README.md)** - Test suite documentation and guidelines

## Quick Links

- [Ballerina Central](https://central.ballerina.io)
- [Ballerina Documentation](https://ballerina.io/learn/)
- [Connector API Reference](ballerina/README.md)

## Version Information

- **Version**: 1.0.0
- **Ballerina Version**: 2201.8.0 or later
- **License**: Apache 2.0

## Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details on how to get started.

## Support

For questions and support:
- Create an issue in this repository
- Visit the [Ballerina Discord](https://discord.gg/ballerinalang)
- Check the [Ballerina documentation](https://ballerina.io/learn/)

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.