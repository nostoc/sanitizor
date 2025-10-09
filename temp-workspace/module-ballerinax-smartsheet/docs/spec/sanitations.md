_Author_:  @nostoc \
_Created_: 28/07/2025 \
_Updated_: 06/08/2025 \
_Edition_: Swan Lake

# Sanitation for OpenAPI specification


This document records the sanitation done on top of the official OpenAPI specification from Smartsheet.
The OpenAPI specification is obtained from [Smartsheet OpenAPI Reference](https://developers.smartsheet.com/api/smartsheet/openapi).
These changes are done in order to improve the overall usability, and as workarounds for some known language limitations.

### Sanitation Steps Applied

1. **Expanded the second element of `DiscussionCreate`'s `allOf` by inlining the object from `#/components/schemas/DiscussionCreateAllOf2`**

   This caused `redeclared symbol 'action'`, `redeclared symbol 'additionalDetails'`, and `redeclared symbol 'objectType'` errors in Ballerina, because both Event and DiscussionCreateAllOf2 defined these fields.

   **Sanitation:**
   - Replaced the second element of the `allOf` array (which was a `$ref` to `#/components/schemas/DiscussionCreateAllOf2` in `openapi.json`) with the full object definition from `#/components/schemas/DiscussionCreateAllOf2` , inlined directly into the `allOf` array.
   - This change was made at `/components/schemas/DiscussionCreate` in the OpenAPI spec.
   - After regenerating the client, the error was resolved and the generated Ballerina type is correct.

> **Note on similar errors and repeated sanitation**
>
> The sanitation described above for `DiscussionCreate` must be repeated for all other records that use an `allOf` composition of `Event` and a second `$ref` (such as `FolderDeleteAllOf2`, etc.) and result in redeclared symbol errors (e.g., `action`, `additionalDetails`, `objectType`) in Ballerina.
>
> **For each affected record, apply the same approach:**
> - Inline the full object definition from the referenced `AllOf2` schema directly into the `allOf` array, replacing the `$ref`.

**Affected records include:**

<details>
<summary>Click to expand full list</summary>

<ul>
<li>FolderDelete</li>
<li>AccountBulkUpdate</li>
<li>ReportPurge</li>
<li>SheetRemoveShareMember</li>
<li>GroupRename</li>
<li>SheetUpdate</li>
<li>DashboardSaveAsNew</li>
<li>FormDelete</li>
<li>AccesstokenRevoke</li>
<li>WorkspaceUpdateRecurringBackup</li>
<li>SheetSendAsAttachment</li>
<li>SheetCreate</li>
<li>ReportRemoveWorkspaceShare</li>
<li>GroupDownloadSheetAccessReport</li>
<li>UserDownloadSheetAccessReport</li>
<li>DashboardRename</li>
<li>FolderRequestBackup</li>
<li>AccountDownloadSheetAccessReport</li>
<li>FormActivate</li>
<li>WorkspaceDelete</li>
<li>DashboardTransferOwnership</li>
<li>WorkspaceRemoveShareMember</li>
<li>SheetLoad</li>
<li>DashboardAddWorkspaceShare</li>
<li>UserSendPasswordReset</li>
<li>SheetRemoveShare</li>
<li>SheetTransferOwnership</li>
<li>ReportLoad</li>
<li>UpdateRequestCreate</li>
<li>UserUpdateUser</li>
<li>SheetRemoveWorkspaceShare</li>
<li>FolderSaveAsNew</li>
<li>AccesstokenAuthorize</li>
<li>UserSendInvite</li>
<li>SheetAddShare</li>
<li>DashboardAddShareMember</li>
<li>SheetExport</li>
<li>UserDeclineInvite</li>
<li>SheetRestore</li>
<li>WorkspaceDeleteRecurringBackup</li>
<li>DashboardDelete</li>
<li>WorkspaceSaveAsNew</li>
<li>DiscussionUpdate</li>
<li>SheetMove</li>
<li>GroupDelete</li>
<li>SheetSaveAsTemplate</li>
<li>AttachmentUpdate</li>
<li>AccesstokenRefresh</li>
<li>DashboardAddPublish</li>
<li>SheetDelete</li>
<li>DiscussionSendcomment</li>
<li>AttachmentDelete</li>
<li>DashboardRemoveShare</li>
<li>SheetCreateCellLink</li>
<li>DashboardRemoveWorkspaceShare</li>
<li>ReportRemoveShare</li>
<li>ReportExport</li>
<li>SheetSendRow</li>
<li>DiscussionDelete</li>
<li>DashboardRemovePublish</li>
<li>DashboardLoad</li>
<li>AttachmentSend</li>
<li>AccountImportUsers</li>
<li>SheetMoveRow</li>
<li>UserAddToAccount</li>
<li>WorkspaceRequestBackup</li>
<li>DashboardUpdate</li>
<li>ReportCreate</li>
<li>UserTransferOwnedGroups</li>
<li>ReportTransferOwnership</li>
<li>UserTransferOwnedItems</li>
<li>GroupTransferOwnership</li>
<li>SheetRename</li>
<li>DashboardMove</li>
<li>ReportAddShareMember</li>
<li>ReportAddWorkspaceShare</li>
<li>ReportSaveAsNew</li>
<li>ReportRemoveShareMember</li>
<li>FolderCreate</li>
<li>UserRemoveShares</li>
<li>FormCreate</li>
<li>UserRemoveFromAccount</li>
<li>ReportAddShare</li>
<li>DashboardRemoveShareMember</li>
<li>WorkspaceTransferOwnership</li>
<li>AccountDownloadLoginHistory</li>
<li>SheetAddWorkspaceShare</li>
<li>WorkspaceExport</li>
<li>AccountDownloadPublishedItemsReport</li>
<li>SheetRequestBackup</li>
<li>DashboardCreate</li>
<li>AttachmentCreate</li>
<li>AccountListSheets</li>
<li>SheetPurge</li>
<li>SheetCopyRow</li>
<li>ReportRestore</li>
<li>DashboardAddShare</li>
<li>ReportRename</li>
<li>ReportMove</li>
<li>DashboardPurge</li>
<li>UserAcceptInvite</li>
<li>AccountDownloadUserList</li>
<li>WorkspaceAddShare</li>
<li>AccountRename</li>
<li>FolderRename</li>
<li>WorkspaceCreate</li>
<li>GroupAddMember</li>
<li>AttachmentLoad</li>
<li>UserRemoveFromGroups</li>
<li>ReportDelete</li>
<li>WorkspaceRemoveShare</li>
<li>SheetSaveAsNew</li>
<li>GroupRemoveMember</li>
<li>WorkspaceAddShareMember</li>
<li>WorkspaceCreateRecurringBackup</li>
<li>DiscussionSend</li>
<li>SheetAddShareMember</li>
<li>AccountUpdateMainContact</li>
<li>WorkspaceRename</li>
<li>DashboardRestore</li>
<li>FolderExport</li>
<li>FormUpdate</li>
<li>FormDeactivate</li>
<li>ReportUpdate</li>
<li>ReportSendAsAttachment</li>
<li>Webhook</li>
</ul>
</details>

2. **Removed duplicate fields from `WebhookAllOf2` to resolve redeclared symbol errors in `Webhook` type.**
3. **Fixed missing descriptions to resolve `undocumented field` warnings in Ballerina code generation**

   Some schema fields were not documented in the generated Ballerina types due to OpenAPI spec formatting issues, even though descriptions were present in the spec.

   **Sanitation:**
   - Moved `description` fields from nested `items` objects or from alongside `$ref` fields to the correct top-level property definitions.
   - For fields that used `$ref`, replaced:
     ```json
     "fieldName": {
       "$ref": "...",
       "description": "..."
     }
     ```
     with:
     ```json
     "fieldName": {
       "allOf": [{ "$ref": "..." }],
       "description": "..."
     }
     ```
   - For array fields, moved the `description` outside the `items` block to the array field itself.

   These fixes ensured that the Ballerina `openapi` tool correctly included field-level documentation in the generated `types.bal`.

4. **Replaced auto-generated schema names with meaningful names**

   The OpenAPI specification contained auto-generated schema names like `InlineResponse200`, `InlineResponse2001`, etc., which resulted in non-descriptive record names in the generated Ballerina types.

   **Sanitation:**
   - Manually renamed schema names like `InlineResponse2007` in the aligned OpenAPI spec to more meaningful names such as `SharedSecretResponse`, `WebhookResponse`, `ContactListResponse`, etc.
   - Updated all corresponding `$ref` references throughout the OpenAPI specification to point to the new schema names.
   - This change improved code readability and maintainability by providing descriptive type names in the generated Ballerina client.


---

## OpenAPI cli command

The following command was used to generate the Ballerina client from the OpenAPI specification. The command should be executed from the repository root directory.

```bash
$ bal openapi -i docs/spec/openapi.yaml --mode client --license docs/license.txt -o ballerina
```
Note: The license year is hardcoded to 2024, change if necessary.
