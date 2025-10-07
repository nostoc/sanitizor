// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/log;




listener http:Listener httpListener = new (9090);

http:Service mockService = service object {
    # Delete Sheet
    #
    # + return - returns can be any of following types; `SuccessResult`, `ErrorDefault`
    resource function delete sheets/[decimal sheetId](@http:Header {name: "Authorization"} string? authorization) returns SuccessResult|ErrorDefault {
        return {
            resultCode: 0,
            message: "SUCCESS"
        };
    }

    # Delete Rows
    #
    # + return - returns can be any of following types; `RowListResponse`, `ErrorNotFound`
    resource function delete sheets/[decimal sheetId]/rows(@http:Header {name: "Authorization"} string? authorization, string ids, boolean ignoreRowsNotFound = false) returns RowListResponse|ErrorNotFound {
        string[] rowIds = re `\s*,\s*`.split(ids);
        decimal[] deletedRowIds = [];

        foreach string rowId in rowIds {
            decimal|error id = decimal:fromString(rowId);
            if id is decimal {
                deletedRowIds.push(id);
            }
        }

        return {
            resultCode: 0,
            message: "SUCCESS",
            result: deletedRowIds
        };
    }

    # Get Folder
    #
    # + return - returns can be any of following types; `Folder`, `ErrorDefault`
    resource function get folders/[decimal folderId](@http:Header {name: "Authorization"} string? authorization, "source"|"distributionLink"|"ownerInfo"|"sheetVersion"? include) returns Folder|ErrorDefault {
        return {
            id: folderId,
            name: "Sample Folder",
            permalink: "https://app.smartsheet.com/folders/" + folderId.toString(),
            sheets: [
                {
                    id: 12345,
                    name: "Sample Sheet 1",
                    permalink: "https://app.smartsheet.com/sheets/12345"
                },
                {
                    id: 12346,
                    name: "Sample Sheet 2",
                    permalink: "https://app.smartsheet.com/sheets/12346"
                }
            ],
            folders: [
                {
                    id: 67890,
                    name: "Subfolder 1",
                    permalink: "https://app.smartsheet.com/folders/67890"
                }
            ],
            reports: [
                {
                    id: 11111,
                    name: "Sample Report",
                    permalink: "https://app.smartsheet.com/reports/11111"
                }
            ]
        };
    }

    # List Sheets
    #
    # + return - returns can be any of following types; `AlternateEmailListResponse`, `ErrorDefault`
    resource function get sheets(@http:Header {name: "Authorization"} string? authorization, "sheetVersion"|"source"? include, string? modifiedSince, decimal accessApiLevel = 0, boolean includeAll = false, boolean numericDates = false, decimal page = 1, decimal pageSize = 100) returns AlternateEmailListResponse|ErrorDefault {
        return {
            pageNumber: page,
            pageSize: pageSize,
            totalPages: 1,
            totalCount: 3,
            data: [
                {
                    id: 12345,
                    name: "Project Planning Sheet",
                    accessLevel: "OWNER",
                    permalink: "https://app.smartsheet.com/sheets/12345",
                    createdAt: "2024-01-15T10:30:00Z",
                    modifiedAt: "2024-01-20T14:45:00Z",
                    version: 5
                },
                {
                    id: 12346,
                    name: "Budget Tracking",
                    accessLevel: "EDITOR",
                    permalink: "https://app.smartsheet.com/sheets/12346",
                    createdAt: "2024-01-10T09:15:00Z",
                    modifiedAt: "2024-01-18T16:20:00Z",
                    version: 3
                },
                {
                    id: 12347,
                    name: "Task Management",
                    accessLevel: "VIEWER",
                    permalink: "https://app.smartsheet.com/sheets/12347",
                    createdAt: "2024-01-05T11:00:00Z",
                    modifiedAt: "2024-01-15T13:30:00Z",
                    version: 7
                }
            ]
        };
    }

    # Get Sheet
    #
    # + return - returns can be any of following types; `FavoriteResponse`, `ErrorDefault`
    resource function get sheets/[decimal sheetId](
            @http:Header {name: "Authorization"} string? authorization,
            @http:Header {name: "Accept"} string? accept,
            "attachments"|"columnType"|"crossSheetReferences"|"discussions"|"filters"|"filterDefinitions"|"format"|"ganttConfig"|"objectValue"|"ownerInfo"|"rowPermalink"|"source"|"writerInfo"? include,
            "filteredOutRows"|"linkInFromCellDetails"|"linksOutToCellsDetails"|"nonexistentCells"? exclude,
            string? columnIds, string? filterId, int? ifVersionAfter, string? rowIds,
            string? rowNumbers, string? rowsModifiedSince,
            decimal accessApiLevel = 0, int level = 0,
            decimal pageSize = 100, decimal page = 1,
            "LETTER"|"LEGAL"|"WIDE"|"ARCHD"|"A4"|"A3"|"A2"|"A1"|"A0" paperSize = "LETTER"
) returns FavoriteResponse|ErrorDefault {
        return <Sheet>{
            id: sheetId,
            name: "Sample Sheet " + sheetId.toString(),
            accessLevel: "OWNER",
            permalink: "https://app.smartsheet.com/sheets/" + sheetId.toString(),
            version: 10,
            totalRowCount: 5,
            createdAt: "2024-01-15T10:30:00Z",
            modifiedAt: "2024-01-20T14:45:00Z",
            owner: "owner@example.com",
            ownerId: 1001,
            dependenciesEnabled: false,
            ganttEnabled: false,
            resourceManagementEnabled: false,
            cellImageUploadEnabled: true,
            hasSummaryFields: false,
            readOnly: false,
            isMultiPicklistEnabled: true,
            resourceManagementType: "NONE",
            effectiveAttachmentOptions: ["FILE", "GOOGLE_DRIVE", "LINK", "BOX_COM", "DROPBOX", "EVERNOTE", "EGNYTE", "ONEDRIVE"],
            columns: [
                {
                    id: 1001,
                    index: 0,
                    title: "Task Name",
                    'type: "TEXT_NUMBER",
                    primary: true,
                    width: 200,
                    validation: false
                },
                {
                    id: 1002,
                    index: 1,
                    title: "Assigned To",
                    'type: "CONTACT_LIST",
                    width: 150,
                    validation: false
                },
                {
                    id: 1003,
                    index: 2,
                    title: "Status",
                    'type: "PICKLIST",
                    options: ["Not Started", "In Progress", "Complete"],
                    width: 100,
                    validation: true
                },
                {
                    id: 1004,
                    index: 3,
                    title: "Due Date",
                    'type: "DATE",
                    width: 120,
                    validation: false
                }
            ],
            rows: [
                {
                    id: 2001,
                    rowNumber: 1,
                    expanded: true,
                    createdAt: "2024-01-15T10:30:00Z",
                    modifiedAt: "2024-01-20T14:45:00Z",
                    sheetId: sheetId,
                    cells: [
                        {columnId: 1001, value: "Project Planning", displayValue: "Project Planning"},
                        {columnId: 1002, value: "john.doe@example.com", displayValue: "John Doe"},
                        {columnId: 1003, value: "In Progress", displayValue: "In Progress"},
                        {columnId: 1004, value: "2024-02-15", displayValue: "02/15/24"}
                    ]
                }
            ]
        };
    }

    # List Columns
    #
    # + return - returns can be any of following types; `ColumnListResponse`, `ErrorDefault`
    resource function get sheets/[decimal sheetId]/columns(@http:Header {name: "Authorization"} string? authorization, int level = 0, decimal page = 1, decimal pageSize = 100, boolean includeAll = false) returns ColumnListResponse|ErrorDefault {
        return {
            pageNumber: page,
            pageSize: pageSize,
            totalPages: 1,
            totalCount: 4,
            data: [
                {
                    id: 1001,
                    index: 0,
                    title: "Task Name",
                    'type: "TEXT_NUMBER",
                    validation: false
                },
                {
                    id: 1002,
                    index: 1,
                    title: "Assigned To",
                    'type: "CONTACT_LIST",
                    validation: false
                },
                {
                    id: 1003,
                    index: 2,
                    title: "Status",
                    'type: "PICKLIST",
                    validation: true
                },
                {
                    id: 1004,
                    index: 3,
                    title: "Due Date",
                    'type: "DATE",
                    validation: false
                }
            ]
        };
    }

    # Get Row
    #
    # + return - returns can be any of following types; `RowResponse`, `ErrorDefault`
    resource function get sheets/[decimal sheetId]/rows/[decimal rowId](@http:Header {name: "Authorization"} string? authorization, "columns"|"filters"? include, "filteredOutRows"|"linkInFromCellDetails"|"linksOutToCellsDetails"|"nonexistentCells"? exclude, decimal accessApiLevel = 0, int level = 0) returns RowResponse|ErrorDefault {
        return {
            id: rowId,
            rowNumber: 1,
            sheetId: sheetId,
            expanded: true,
            createdAt: "2024-01-15T10:30:00Z",
            modifiedAt: "2024-01-20T14:45:00Z",
            cells: [
                {
                    columnId: 1001,
                    value: "Sample Task",
                    displayValue: "Sample Task"
                },
                {
                    columnId: 1002,
                    value: "user@example.com",
                    displayValue: "Sample User"
                },
                {
                    columnId: 1003,
                    value: "In Progress",
                    displayValue: "In Progress"
                },
                {
                    columnId: 1004,
                    value: "2024-02-15",
                    displayValue: "02/15/24"
                }
            ]
        };
    }

    # List Users
    #
    # + return - returns can be any of following types; `UserListResponse`, `ErrorDefault`
    resource function get users(@http:Header {name: "Authorization"} string? authorization, string? email, string? include, boolean includeAll = false, boolean numericDates = false, decimal page = 1, decimal pageSize = 100) returns UserListResponse|ErrorDefault {
        return {
            pageNumber: page,
            pageSize: pageSize,
            totalPages: 1,
            totalCount: 3,
            data: [
                {
                    id: 1001,
                    firstName: "John",
                    lastName: "Doe",
                    name: "John Doe",
                    email: "john.doe@example.com",
                    status: "ACTIVE",
                    admin: false,
                    groupAdmin: false,
                    licensedSheetCreator: true,
                    resourceViewer: false,
                    sheetCount: -1
                },
                {
                    id: 1002,
                    firstName: "Jane",
                    lastName: "Smith",
                    name: "Jane Smith",
                    email: "jane.smith@example.com",
                    status: "ACTIVE",
                    admin: true,
                    groupAdmin: true,
                    licensedSheetCreator: true,
                    resourceViewer: true,
                    sheetCount: -1
                },
                {
                    id: 1003,
                    firstName: "Bob",
                    lastName: "Johnson",
                    name: "Bob Johnson",
                    email: "bob.johnson@example.com",
                    status: "ACTIVE",
                    admin: false,
                    groupAdmin: false,
                    licensedSheetCreator: false,
                    resourceViewer: false,
                    sheetCount: -1
                }
            ]
        };
    }

    # Get Current User
    #
    # + return - returns can be any of following types; `UserImgProfileResponse`, `ErrorDefault`
    resource function get users/me(@http:Header {name: "Authorization"} string? authorization, "groups"? include) returns UserImgProfileResponse|ErrorDefault {
        return {
            id: 1001,
            firstName: "Current",
            lastName: "User",
            email: "current.user@example.com",
            locale: "en_US",
            timeZone: "US/Pacific",
            admin: false,
            groupAdmin: false,
            licensedSheetCreator: true,
            resourceViewer: false,
            sheetCount: -1,
            title: "Project Manager",
            department: "Engineering",
            company: "Example Corp",
            workPhone: "+1-555-123-4567",
            mobilePhone: "+1-555-987-6543",
            account: {
                id: 12345,
                name: "Example Corp Account"
            },
            data: include == "groups" ? [
                    {
                        id: 5001,
                        name: "Project Managers",
                        description: "Group for all project managers"
                    },
                    {
                        id: 5002,
                        name: "Engineering Team",
                        description: "Engineering department group"
                    }
                ] : []
        };
    }
    # List Workspaces
    #
    # + return - returns can be any of following types; `WorkspaceShareListResponse`, `ErrorDefault`
    resource function get workspaces(@http:Header {name: "Authorization"} string? authorization, decimal accessApiLevel = 0, boolean includeAll = false, decimal page = 1, decimal pageSize = 100) returns WorkspaceShareListResponse|ErrorDefault {
        return {
            pageNumber: page,
            pageSize: pageSize,
            totalPages: 1,
            totalCount: 2,
            data: [
                {
                    id: 3001,
                    name: "Marketing Workspace",
                    accessLevel: "OWNER",
                    permalink: "https://app.smartsheet.com/workspaces/3001"
                },
                {
                    id: 3002,
                    name: "Engineering Workspace",
                    accessLevel: "EDITOR",
                    permalink: "https://app.smartsheet.com/workspaces/3002"
                }
            ]
        };
    }

    # Add Columns
    #
    # + return - returns can be any of following types; `ColumnCreateResponseOk`, `ErrorDefault`
    resource function post sheets/[decimal sheetId]/columns(@http:Header {name: "Authorization"} string? authorization, @http:Payload ColumnObjectAttributes payload, @http:Header {name: "Content-Type"} string? contentType = "application/json") returns ColumnCreateResponseOk {
        decimal newColumnId = 2000 + sheetId;
        return {
            body: {
                resultCode: 0,
                message: "SUCCESS",
                result: [
                    {
                        id: newColumnId,
                        index: payload.index ?: 0,
                        title: payload.title ?: "New Column",
                        'type: payload.'type ?: "TEXT_NUMBER",
                        validation: payload.validation ?: false,
                        width: payload.width ?: 150,
                        options: payload.options ?: []
                    }
                ]
            }
        };
    }

    # Add Rows
    #
    # + return - returns can be any of following types; `RowCreateResponseOk`, `ErrorDefault`
    resource function post sheets/[decimal sheetId]/rows(@http:Header {name: "Authorization"} string? authorization, @http:Payload SheetIdRowsBody1 payload, decimal accessApiLevel = 0, @http:Header {name: "Content-Type"} string? contentType = "application/json", boolean allowPartialSuccess = false, boolean overrideValidation = false) returns RowMoveResponseOk|ErrorDefault {
        decimal newRowId = 3000 + sheetId;
        return {
            body: {
                resultCode: 0,
                message: "SUCCESS",
                result: [
                    {
                        id: newRowId,
                        rowNumber: 1,
                        sheetId: sheetId,
                        expanded: true,
                        createdAt: "2024-08-11T10:30:00Z",
                        modifiedAt: "2024-08-11T10:30:00Z",
                        version: 1,
                        cells: payload is Row ? payload.cells : []
                    }
                ]
            }
        };
    }

    # Update Sheet
    #
    # + return - returns can be any of following types; `AttachmentListResponse`, `ErrorDefault`
    resource function put sheets/[decimal sheetId](@http:Header {name: "Authorization"} string? authorization, @http:Payload UpdateSheet payload, decimal accessApiLevel = 0) returns AttachmentListResponse {
        return {
            resultCode: 0,
            message: "SUCCESS",
            result: {
                id: sheetId,
                name: payload.name ?: "Updated Sheet",
                accessLevel: "OWNER",
                permalink: "https://app.smartsheet.com/sheets/" + sheetId.toString(),
                version: 11,
                totalRowCount: 5,
                createdAt: "2024-01-15T10:30:00Z",
                modifiedAt: "2024-08-11T10:30:00Z",
                userSettings: payload.userSettings,
                projectSettings: payload.projectSettings
            }
        };
    }

    # Update Rows
    #
    # + return - returns can be any of following types; `RowUpdateResponseOk`, `ErrorDefault`
    resource function put sheets/[decimal sheetId]/rows(@http:Header {name: "Authorization"} string? authorization, @http:Payload SheetIdRowsBody payload, decimal accessApiLevel = 0, @http:Header {name: "Content-Type"} string? contentType = "application/json", boolean allowPartialSuccess = false, boolean overrideValidation = false) returns RowCopyResponse|ErrorDefault {
        return {
            resultCode: 0,
            message: "SUCCESS",
            result: [
                {
                    id: payload is Row ? (payload.id ?: 2001) : 2001,
                    rowNumber: 1,
                    expanded: true,
                    createdAt: "2024-01-15T10:30:00Z",
                    modifiedAt: "2024-08-11T10:30:00Z",
                    version: 12,
                    cells: payload is Row ? payload.cells : []
                }
            ]
        };
    }
};

function init() returns error? {
    if isLiveServer {
        log:printInfo("Skipping mock server initialization as the tests are running on live server");
        return;
    }
    log:printInfo("Initiating mock server");
    check httpListener.attach(mockService, "/");
    check httpListener.'start();
}

public type ErrorDefault record {|
    *http:DefaultStatusCodeResponse;
    Error body;
|};

public type ColumnCreateResponseOk record {|
    *http:Ok;
    ColumnCreateResponse body;
|};

public type RowMoveResponseOk record {|
    *http:Ok;
    RowMoveResponse body;
|};

public type ErrorNotFound record {|
    *http:NotFound;
    Error body;
|};