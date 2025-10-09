# smartsheet Connector



## Overview

The smartsheet connector allows you to integrate with smartsheet services seamlessly. This connector provides access to 184 operations.

## Features

- 184 API operations available
- 1 practical examples included

## Prerequisites

- **Required**: Generate an API access token from your smartsheet account
- **Required**: Install Ballerina Swan Lake 2201.x or later
- *Optional*: Ensure you have appropriate permissions to manage projects and tasks
- **Required**: Ensure network connectivity to smartsheet API endpoints

## Quickstart

### Installation

Add the dependency to your `Ballerina.toml` file.

### Configuration

Create a `Config.toml` file with your credentials.

### Basic Usage

```ballerina
import ballerinax/smartsheet;

public function main() returns error? {
    // Initialize the connector
    smartsheet:Client client = check new();
    
    // Example operation
    // Get Contact
    var result = check client->contacts();
}
```

## Examples

- **project_task_management**: Demonstrates project and task management operations using the connector (with configuration)

## API Reference

### Available Operations

#### contacts
- **Method**: GET
- **Description**: List Contacts

#### contacts
- **Method**: GET
- **Description**: Get Contact

#### events
- **Method**: GET
- **Description**: List events

#### favorites
- **Method**: GET
- **Description**: Get Favorites

#### favorites
- **Method**: POST
- **Description**: Add Favorites

#### favorites
- **Method**: DELETE
- **Description**: Delete Multiple Favorites

#### favorites
- **Method**: GET
- **Description**: Is Favorite

#### favorites
- **Method**: DELETE
- **Description**: Delete Favorite

#### filteredEvents
- **Method**: POST
- **Description**: List filtered events

#### folders
- **Method**: GET
- **Description**: Get Folder

#### folders
- **Method**: PUT
- **Description**: Update Folder

#### folders
- **Method**: DELETE
- **Description**: Delete Folder

#### folders
- **Method**: POST
- **Description**: Copy Folder

#### folders
- **Method**: GET
- **Description**: List Folders

#### folders
- **Method**: POST
- **Description**: Create Folder

#### folders
- **Method**: POST
- **Description**: Move Folder

#### folders
- **Method**: POST
- **Description**: Create Sheet in Folder

#### folders
- **Method**: POST
- **Description**: Import Sheet into Folder

#### folders
- **Method**: GET
- **Description**: # Deprecated

#### groups
- **Method**: GET
- **Description**: List Org Groups

#### groups
- **Method**: POST
- **Description**: Add Group

#### groups
- **Method**: GET
- **Description**: Get Group

#### groups
- **Method**: PUT
- **Description**: Update Group

#### groups
- **Method**: DELETE
- **Description**: Delete Group

#### groups
- **Method**: POST
- **Description**: Add Group Members

#### groups
- **Method**: DELETE
- **Description**: Delete Group Members

#### home
- **Method**: GET
- **Description**: List Folders in Home

#### home
- **Method**: POST
- **Description**: # Deprecated

#### imageurls
- **Method**: POST
- **Description**: List Image URLs

#### reports
- **Method**: GET
- **Description**: List Reports

#### reports
- **Method**: GET
- **Description**: Get Report

#### reports
- **Method**: POST
- **Description**: Send report via email

#### reports
- **Method**: GET
- **Description**: Gets a Report's publish settings

#### reports
- **Method**: PUT
- **Description**: Set a Report's publish status

#### reports
- **Method**: GET
- **Description**: List Report Shares

#### reports
- **Method**: POST
- **Description**: Share Report

#### reports
- **Method**: GET
- **Description**: Get Report Share

#### reports
- **Method**: PUT
- **Description**: Update Report Share

#### reports
- **Method**: DELETE
- **Description**: Delete Report Share

#### search
- **Method**: GET
- **Description**: Search Everything

#### search
- **Method**: GET
- **Description**: Search Sheet

#### serverinfo
- **Method**: GET
- **Description**: Gets application constants.

#### sheets
- **Method**: GET
- **Description**: List Sheets

#### sheets
- **Method**: POST
- **Description**: # Deprecated

#### sheets
- **Method**: POST
- **Description**: # Deprecated

#### sheets
- **Method**: GET
- **Description**: Get Sheet

#### sheets
- **Method**: PUT
- **Description**: Update Sheet

#### sheets
- **Method**: DELETE
- **Description**: Delete Sheet

#### sheets
- **Method**: GET
- **Description**: List Attachments

#### sheets
- **Method**: POST
- **Description**: Attach File or URL to Sheet

#### sheets
- **Method**: GET
- **Description**: Get Attachment

#### sheets
- **Method**: DELETE
- **Description**: Delete Attachment

#### sheets
- **Method**: GET
- **Description**: List Versions

#### sheets
- **Method**: POST
- **Description**: Attach New version

#### sheets
- **Method**: DELETE
- **Description**: Delete All Versions

#### sheets
- **Method**: GET
- **Description**: List All Automation Rules

#### sheets
- **Method**: GET
- **Description**: Get an Automation Rule

#### sheets
- **Method**: PUT
- **Description**: Update an Automation Rule

#### sheets
- **Method**: DELETE
- **Description**: Delete an Automation Rule

#### sheets
- **Method**: GET
- **Description**: List Columns

#### sheets
- **Method**: POST
- **Description**: Add Columns

#### sheets
- **Method**: GET
- **Description**: Get Column

#### sheets
- **Method**: PUT
- **Description**: Update Column

#### sheets
- **Method**: DELETE
- **Description**: Delete Column

#### sheets
- **Method**: GET
- **Description**: Get a comment

#### sheets
- **Method**: PUT
- **Description**: Edit a comment

#### sheets
- **Method**: DELETE
- **Description**: Delete a comment

#### sheets
- **Method**: POST
- **Description**: Attach File or URL to Comment

#### sheets
- **Method**: POST
- **Description**: Copy Sheet

#### sheets
- **Method**: GET
- **Description**: List Cross-sheet References

#### sheets
- **Method**: POST
- **Description**: Create Cross-sheet References

#### sheets
- **Method**: GET
- **Description**: Get Cross-sheet Reference

#### sheets
- **Method**: GET
- **Description**: List Discussions

#### sheets
- **Method**: POST
- **Description**: Create a Discussion

#### sheets
- **Method**: GET
- **Description**: Get Discussion

#### sheets
- **Method**: DELETE
- **Description**: Delete a Discussion

#### sheets
- **Method**: GET
- **Description**: List Discussion Attachments

#### sheets
- **Method**: POST
- **Description**: Create a comment

#### sheets
- **Method**: POST
- **Description**: Send Sheet via Email

#### sheets
- **Method**: POST
- **Description**: Move Sheet

#### sheets
- **Method**: GET
- **Description**: List Proofs

#### sheets
- **Method**: GET
- **Description**: Get Proof

#### sheets
- **Method**: PUT
- **Description**: Update Proof Status

#### sheets
- **Method**: DELETE
- **Description**: Delete Proof

#### sheets
- **Method**: GET
- **Description**: List Proof Attachments

#### sheets
- **Method**: POST
- **Description**: Attach File to Proof

#### sheets
- **Method**: GET
- **Description**: List Proof Discussions

#### sheets
- **Method**: POST
- **Description**: Create Proof Discussion

#### sheets
- **Method**: GET
- **Description**: List Proof Request Actions

#### sheets
- **Method**: POST
- **Description**: Create Proof Request

#### sheets
- **Method**: DELETE
- **Description**: Delete Proof Requests

#### sheets
- **Method**: GET
- **Description**: List Proof Versions

#### sheets
- **Method**: POST
- **Description**: Create Proof Version

#### sheets
- **Method**: DELETE
- **Description**: Delete Proof Version

#### sheets
- **Method**: GET
- **Description**: Get Sheet Publish Status

#### sheets
- **Method**: PUT
- **Description**: Set Sheet Publish Status

#### sheets
- **Method**: PUT
- **Description**: Update Rows

#### sheets
- **Method**: POST
- **Description**: Add Rows

#### sheets
- **Method**: DELETE
- **Description**: Delete Rows

#### sheets
- **Method**: POST
- **Description**: Send Rows via Email

#### sheets
- **Method**: POST
- **Description**: Copy Rows to Another Sheet

#### sheets
- **Method**: POST
- **Description**: Move Rows to Another Sheet

#### sheets
- **Method**: GET
- **Description**: Get Row

#### sheets
- **Method**: GET
- **Description**: List Row Attachments

#### sheets
- **Method**: POST
- **Description**: Attach File or URL to Row

#### sheets
- **Method**: POST
- **Description**: Add Image to Cell

#### sheets
- **Method**: GET
- **Description**: List Cell History

#### sheets
- **Method**: GET
- **Description**: List Discussions with a Row

#### sheets
- **Method**: POST
- **Description**: Create a Discussion on a Row

#### sheets
- **Method**: POST
- **Description**: Create Proof

#### sheets
- **Method**: GET
- **Description**: List Sent Update Requests

#### sheets
- **Method**: GET
- **Description**: Get Sent Update Request

#### sheets
- **Method**: DELETE
- **Description**: Delete Sent Update Request

#### sheets
- **Method**: GET
- **Description**: Get Sheet Summary

#### sheets
- **Method**: GET
- **Description**: Get Summary Fields

#### sheets
- **Method**: PUT
- **Description**: Update Summary Fields

#### sheets
- **Method**: POST
- **Description**: Add Summary Fields

#### sheets
- **Method**: DELETE
- **Description**: Delete Summary Fields

#### sheets
- **Method**: POST
- **Description**: Add Image to Sheet Summary

#### sheets
- **Method**: GET
- **Description**: List Update Requests

#### sheets
- **Method**: POST
- **Description**: Create an Update Request

#### sheets
- **Method**: GET
- **Description**: Get an Update Request

#### sheets
- **Method**: PUT
- **Description**: Update an Update Request

#### sheets
- **Method**: DELETE
- **Description**: Delete an Update Request

#### sheets
- **Method**: GET
- **Description**: List Sheet Shares

#### sheets
- **Method**: POST
- **Description**: Share Sheet

#### sheets
- **Method**: GET
- **Description**: Get Sheet Share.

#### sheets
- **Method**: PUT
- **Description**: Update Sheet Share.

#### sheets
- **Method**: DELETE
- **Description**: Delete Sheet Share

#### sheets
- **Method**: POST
- **Description**: Sort Rows in Sheet

#### sheets
- **Method**: GET
- **Description**: Get Sheet Version

#### sights
- **Method**: GET
- **Description**: List Dashboards

#### sights
- **Method**: GET
- **Description**: Get Dashboard

#### sights
- **Method**: PUT
- **Description**: Update Dashboard

#### sights
- **Method**: DELETE
- **Description**: Delete Dashboard

#### sights
- **Method**: POST
- **Description**: Copy Dashboard

#### sights
- **Method**: POST
- **Description**: Move Dashboard

#### sights
- **Method**: GET
- **Description**: Get Dashboard Publish Status

#### sights
- **Method**: PUT
- **Description**: Set Dashboard Publish Status

#### sights
- **Method**: GET
- **Description**: List Dashboard Shares

#### sights
- **Method**: POST
- **Description**: Share Dashboard

#### sights
- **Method**: GET
- **Description**: Get Dashboard Share

#### sights
- **Method**: PUT
- **Description**: Update Dashboard Share

#### sights
- **Method**: DELETE
- **Description**: Delete Dashboard Share

#### templates
- **Method**: GET
- **Description**: List User-Created Templates

#### templates
- **Method**: GET
- **Description**: List Public Templates

#### token
- **Method**: POST
- **Description**: Gets or Refreshes an Access Token

#### token
- **Method**: DELETE
- **Description**: Revoke Access Token

#### users
- **Method**: GET
- **Description**: List Users

#### users
- **Method**: POST
- **Description**: Add User

#### users
- **Method**: GET
- **Description**: Get Current User

#### users
- **Method**: GET
- **Description**: List Org Sheets

#### users
- **Method**: GET
- **Description**: Get User

#### users
- **Method**: PUT
- **Description**: Update User

#### users
- **Method**: DELETE
- **Description**: Remove User

#### users
- **Method**: GET
- **Description**: List Alternate Emails

#### users
- **Method**: POST
- **Description**: Add Alternate Emails

#### users
- **Method**: GET
- **Description**: Get Alternate Email

#### users
- **Method**: DELETE
- **Description**: Delete Alternate Email

#### users
- **Method**: POST
- **Description**: Make Alternate Email Primary

#### users
- **Method**: POST
- **Description**: Deactivate User

#### users
- **Method**: POST
- **Description**: Update User Profile Image

#### users
- **Method**: POST
- **Description**: Reactivate User

#### webhooks
- **Method**: GET
- **Description**: List Webhooks

#### webhooks
- **Method**: POST
- **Description**: Create Webhook

#### webhooks
- **Method**: GET
- **Description**: Get Webhook

#### webhooks
- **Method**: PUT
- **Description**: Update Webhook

#### webhooks
- **Method**: DELETE
- **Description**: Delete Webhook

#### webhooks
- **Method**: POST
- **Description**: Reset Shared Secret

#### workspaces
- **Method**: GET
- **Description**: List Workspaces

#### workspaces
- **Method**: POST
- **Description**: Create Workspace

#### workspaces
- **Method**: GET
- **Description**: Get Workspace

#### workspaces
- **Method**: PUT
- **Description**: Update Workspace

#### workspaces
- **Method**: DELETE
- **Description**: Delete Workspace

#### workspaces
- **Method**: POST
- **Description**: Copy Workspace

#### workspaces
- **Method**: GET
- **Description**: List Workspace Folders

#### workspaces
- **Method**: POST
- **Description**: Create a Folder

#### workspaces
- **Method**: GET
- **Description**: List Workspace Shares

#### workspaces
- **Method**: POST
- **Description**: Share Workspace

#### workspaces
- **Method**: GET
- **Description**: Get Workspace Share

#### workspaces
- **Method**: PUT
- **Description**: Update Workspace Share

#### workspaces
- **Method**: DELETE
- **Description**: Delete Workspace Share

#### workspaces
- **Method**: POST
- **Description**: Create Sheet in Workspace

#### workspaces
- **Method**: POST
- **Description**: Import Sheet into Workspace

## Contributing

Contributions are welcome!

## License

This project is licensed under the Apache License 2.0.