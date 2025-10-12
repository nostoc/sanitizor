# smartsheet Examples

This directory contains practical examples demonstrating how to use the smartsheet Ballerina connector.

## Getting Started

# Getting Started

This guide will help you quickly get started with the Smartsheet Ballerina connector using the provided examples.

## Prerequisites

Before you begin, ensure you have:
- [Ballerina](https://ballerina.io/downloads/) installed (version 2201.0.0 or later)
- A Smartsheet account
- A Smartsheet API access token

## Step 1: Get Your Smartsheet API Token

1. Log in to your Smartsheet account
2. Go to **Account** > **Apps & Integrations** > **API Access**
3. Click **Generate new access token**
4. Copy and securely store your access token

## Step 2: Start with the Recommended Example

### 🚀 Begin with: `project_task_management`

The `project_task_management` example is the best starting point because it demonstrates core Smartsheet operations like creating sheets, adding rows, and managing project data.

## Step 3: Configure the Example

1. **Clone or download** the connector examples to your local machine

2. **Navigate to the example directory:**
   ```bash
   cd examples/project_task_management
   ```

3. **Configure your credentials:**
   
   Create a `Config.toml` file in the example directory:
   ```toml
   [smartsheet]
   accessToken = "YOUR_SMARTSHEET_ACCESS_TOKEN"
   ```

   Or set environment variables:
   ```bash
   export SMARTSHEET_ACCESS_TOKEN="your_access_token_here"
   ```

## Step 4: Run the Example

1. **Install dependencies:**
   ```bash
   bal build
   ```

2. **Run the example:**
   ```bash
   bal run
   ```

3. **Expected output:**
   The example will create a new sheet, add tasks, and demonstrate various project management operations. You should see console output showing the operations being performed.

## Common Configuration Steps

### Authentication Setup
```ballerina
import ballerina/smartsheet;

// Initialize the client with your access token
smartsheet:Client smartsheetClient = check new({
    auth: {
        token: "YOUR_ACCESS_TOKEN"
    }
});
```

### Basic Error Handling
```ballerina
// Always handle potential errors
smartsheet:SheetResponse|error result = smartsheetClient->getSheet(sheetId);
if (result is smartsheet:SheetResponse) {
    // Process successful response
    io:println("Sheet retrieved successfully");
} else {
    // Handle error
    io:println("Error: ", result.message());
}
```

## Troubleshooting Tips

### ❌ Common Issues and Solutions

1. **Authentication Error (401 Unauthorized)**
   - ✅ Verify your access token is correct
   - ✅ Ensure the token hasn't expired
   - ✅ Check that the token has necessary permissions

2. **Module Not Found Error**
   ```bash
   bal pull ballerina/smartsheet:1.0.0
   ```

3. **Configuration File Issues**
   - ✅ Ensure `Config.toml` is in the correct directory
   - ✅ Check TOML syntax is valid
   - ✅ Verify environment variables are set correctly

4. **Rate Limiting (429 Too Many Requests)**
   - ✅ Add delays between API calls
   - ✅ Implement retry logic with exponential backoff

5. **Sheet/Resource Not Found (404)**
   - ✅ Verify the sheet ID exists
   - ✅ Ensure you have access permissions to the resource

### 🐛 Debug Mode
Run with verbose logging to see detailed information:
```bash
bal run --debug
```

## Understanding the Example Output

When you run the `project_task_management` example, you'll see:
- Sheet creation confirmation with the new sheet ID
- Task addition results
- Column updates and formatting changes
- Any error messages with descriptions

## Next Steps

After successfully running your first example:

### 1. Explore More Examples
- Try other examples that match your use case
- Experiment with different Smartsheet operations

### 2. Customize for Your Needs
- Modify the example to work with your existing sheets
- Add your own business logic
- Integrate with other systems

### 3. Key Operations to Learn
```ballerina
// Essential operations for most use cases
smartsheet:Sheet sheet = check smartsheetClient->createSheet(sheetData);
smartsheet:RowResponse rows = check smartsheetClient->addRows(sheetId, rowData);
smartsheet:ColumnResponse column = check smartsheetClient->addColumn(sheetId, columnData);
```

### 4. Best Practices
- Always handle errors appropriately
- Use batch operations for better performance
- Implement proper logging for production use
- Follow Smartsheet API rate limits

### 5. Build Your Own Integration
- Start with the working example as a template
- Gradually add your specific requirements
- Test thoroughly with your Smartsheet workspace

## Additional Resources

- [Smartsheet API Documentation](https://smartsheet-platform.github.io/api-docs/)
- [Ballerina Language Documentation](https://ballerina.io/learn/)
- [Connector API Reference](https://central.ballerina.io/ballerina/smartsheet/1.0.0)

## Need Help?

If you encounter issues:
1. Check the troubleshooting section above
2. Review the example code comments
3. Consult the Smartsheet API documentation
4. Verify your permissions in Smartsheet

Happy coding with Smartsheet and Ballerina! 🎉

## Available Examples

# Smartsheet Connector Examples

This document provides detailed descriptions of the examples available for the Smartsheet Ballerina connector v1.0.0. Each example demonstrates different aspects of integrating with Smartsheet's API for comprehensive project and data management.

## project_task_management

### Title
**Project Task Management** - Complete project lifecycle management with automated task tracking

### Description
Demonstrates end-to-end project management capabilities including sheet creation, task assignment, progress tracking, and team collaboration through Smartsheet's comprehensive API.

### Problem it Solves
- **Manual Project Tracking**: Eliminates the need for manual project status updates and task management
- **Team Coordination**: Streamlines communication and task assignment across distributed teams
- **Progress Visibility**: Provides real-time insights into project progress and bottlenecks
- **Resource Management**: Helps optimize resource allocation and workload distribution

### Key Concepts and Features Showcased

#### Core Sheet Operations
- **Sheet Creation and Configuration**: Creating project sheets with custom columns and formatting
- **Template Integration**: Leveraging Smartsheet templates for consistent project structures
- **Sheet Sharing and Permissions**: Managing access levels for different team members

#### Task Management
- **Row Operations**: Adding, updating, and organizing project tasks as sheet rows
- **Column Management**: Setting up custom fields for task properties (status, priority, assignee)
- **Cell Operations**: Updating individual task attributes and creating cell links between related items

#### Collaboration Features
- **Discussion Threads**: Creating and managing task-specific discussions
- **Comment System**: Adding contextual comments to tasks and project updates
- **Attachment Management**: Uploading and organizing project documents and files

#### Automation and Workflows
- **Update Requests**: Automating status update requests to team members
- **Notification System**: Setting up automated alerts for task deadlines and changes
- **Webhook Integration**: Real-time event handling for project updates

#### Reporting and Analytics
- **Report Generation**: Creating summary reports for project stakeholders
- **Dashboard Creation**: Building visual dashboards for project metrics
- **Data Export**: Extracting project data for external analysis

### Prerequisites and Setup Required

#### Authentication Setup
- Smartsheet API access token or OAuth2 credentials
- Proper workspace permissions for sheet creation and management
- User account with appropriate license level for advanced features

#### Environment Configuration
```ballerina
smartsheet:ConnectionConfig config = {
    auth: {
        token: "your-api-token"
    }
};
```

#### Required Permissions
- Create and modify sheets within designated workspaces
- Share sheets with team members
- Create reports and dashboards
- Manage webhooks (if using real-time features)

#### Dependencies
- Ballerina HTTP client for API communication
- JSON processing capabilities for data manipulation
- Error handling for robust operation management

### Expected Outcomes

#### Functional Results
- **Automated Project Setup**: New projects automatically configured with standardized structure
- **Streamlined Task Assignment**: Team members receive automated task assignments with clear requirements
- **Real-time Progress Tracking**: Live updates on project status and task completion
- **Enhanced Team Communication**: Centralized discussion threads and comment systems

#### Technical Demonstrations
- **API Integration Patterns**: Best practices for Smartsheet API usage in Ballerina
- **Error Handling**: Robust error management for API operations
- **Data Synchronization**: Maintaining consistency between local application state and Smartsheet
- **Performance Optimization**: Efficient batch operations and API rate limit management

#### Business Value
- **Reduced Administrative Overhead**: Automated project management reduces manual coordination effort
- **Improved Visibility**: Real-time project insights enable better decision making
- **Enhanced Accountability**: Clear task assignments and progress tracking improve team accountability
- **Scalable Process**: Standardized approach that scales across multiple projects and teams

#### Learning Outcomes
- Understanding of Smartsheet's data model and API structure
- Implementation of collaborative workflow patterns
- Integration of real-time notifications and updates
- Best practices for managing complex project data relationships

This example serves as a comprehensive reference for building sophisticated project management solutions using the Smartsheet connector, demonstrating both basic operations and advanced integration patterns suitable for enterprise-level applications.

## Prerequisites

Before running the examples:

1. **Ballerina Installation**: Ensure you have Ballerina installed on your system
2. **API Credentials**: Set up the required API credentials and configuration
3. **Dependencies**: All necessary dependencies will be automatically downloaded when you run the examples

## Running Examples

To run any example:

1. Navigate to the specific example directory
2. Update the configuration file with your credentials
3. Run the example:
   ```bash
   bal run
   ```

## Configuration

Each example may require specific configuration. Check the individual example directories for:
- `Config.toml` files for configuration parameters
- Environment variable requirements
- Any additional setup steps

## Support

If you encounter issues with any examples:
- Check the connector's main documentation
- Verify your configuration and credentials
- Create an issue in the connector's repository with details about the problem