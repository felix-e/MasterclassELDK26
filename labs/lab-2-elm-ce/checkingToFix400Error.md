Optimized tool selectionI’ll give you PowerShell you can run as-is with a few variables filled in, covering both sides: the Logic App run payload and the Entitlement Management custom extension/policy configuration in Graph.

Before I hand over runnable snippets, I’m checking the current Learn docs terminology for the custom extension resource names so the script uses the right Graph paths.

Ran Microsoft Docs Search 
Completed with input: {
  "query": "Microsoft Graph entitlement management custom extension callback resume callbackUriPath accessPackageAssignmentWorkflowExtension PowerShell"
}

The docs search returned a large result file, so I’m reading just the top snippets now and then I’ll turn that into concise PowerShell.

Read [](file:///Users/felixelliott/Library/Application%20Support/Code/User/workspaceStorage/1fc516/GitHub.copilot-chat/chat-session-resources/c3c83a09-3002-4989-bed5-34ff7bc47463/call_pzi3JJzy7EBC6ifHR4i1wric__vscode-1780546583496/content.json)

The Learn snippets confirm the key condition: Graph only accepts resume when the assignment request is actually `WaitingForCallback`. I’m fetching the cmdlet page to capture the exact body shape.

Ran Microsoft Docs Fetch 
Completed with input: {
  "url": "https://learn.microsoft.com/powershell/module/microsoft.graph.beta.identity.governance/resume-mgbetaentitlementmanagementaccesspackageassignmentrequest?view=graph-powershell-beta"
}

I’ve got the authoritative cmdlet page locally now; reading the example section should be enough to avoid overfitting to a remembered payload shape.

Searched for regex `customExtensionStageInstanceId|WaitingForCallback|callback|Resume-MgBetaEntitlementManagementAccessPackageAssignmentRequest` (`/Users/felixelliott/Library/Application Support/Code/User/workspaceStorage/1fc516/GitHub.copilot-chat/chat-session-resources/c3c83a09-3002-4989-bed5-34ff7bc47463/call_SSFmEXzEHtKiHyFxRI6eIq36__vscode-1780546583498/content.txt`), no results

Workspace search won’t index that generated docs file cleanly, so I’m reading the relevant chunk directly.

Read [](file:///Users/felixelliott/Library/Application%20Support/Code/User/workspaceStorage/1fc516/GitHub.copilot-chat/chat-session-resources/c3c83a09-3002-4989-bed5-34ff7bc47463/call_SSFmEXzEHtKiHyFxRI6eIq36__vscode-1780546583498/content.txt#1-1), lines 1 to 220

Below are PowerShell blocks for the checks. They’re written to be diagnostic first, so the only block that actually calls `/resume` is clearly marked.

**1. Connect To Azure And Graph**

```pwsh
$tenantId = "8f87362b-5dd3-45dd-a667-cbff144e3863"
$subscriptionId = "41f018dd-427b-445f-9262-6b32b603662e"

Install-Module Az.Accounts -Scope CurrentUser -Force
Install-Module Microsoft.Graph.Beta.Identity.Governance -Scope CurrentUser -Force

Connect-AzAccount -Tenant $tenantId -Subscription $subscriptionId

Connect-MgGraph -TenantId $tenantId -Scopes @(
    "EntitlementManagement.Read.All",
    "EntitlementManagement.ReadWrite.All"
)

Import-Module Microsoft.Graph.Beta.Identity.Governance
```

**2. Get The Latest Logic App Trigger Payload**

Set `$triggerName` if you know it. If not, run the trigger-list block first.

```pwsh
$resourceGroupName = "entraLab"
$workflowName = "2ProvisionAdmin"
$apiVersion = "2019-05-01"

$workflowBasePath = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Logic/workflows/$workflowName"

$triggers = Invoke-AzRestMethod `
    -Method GET `
    -Path "$workflowBasePath/triggers?api-version=$apiVersion" |
    Select-Object -ExpandProperty Content |
    ConvertFrom-Json

$triggers.value | Select-Object name, @{ Name = "state"; Expression = { $_.properties.state } }
```

Then use the real trigger name:

```pwsh
$triggerName = "manual"

$histories = Invoke-AzRestMethod `
    -Method GET `
    -Path "$workflowBasePath/triggers/$triggerName/histories?api-version=$apiVersion" |
    Select-Object -ExpandProperty Content |
    ConvertFrom-Json

$latestTriggerHistory = $histories.value |
    Sort-Object { $_.properties.startTime } -Descending |
    Select-Object -First 1

$latestTriggerHistory | Select-Object name, @{ Name = "status"; Expression = { $_.properties.status } }, @{ Name = "startTime"; Expression = { $_.properties.startTime } }

$triggerOutputs = Invoke-RestMethod -Method GET -Uri $latestTriggerHistory.properties.outputsLink.uri
$triggerBody = $triggerOutputs.body

$triggerBody | ConvertTo-Json -Depth 50
```

**3. Extract CallbackUriPath, Stage Instance ID, And Assignment Request ID**

This helper searches case-insensitively through the callback body, which is handy because Logic App schemas often change casing.

```pwsh
function Get-DeepPropertyValue {
    param(
        [Parameter(Mandatory)]
        [object] $InputObject,

        [Parameter(Mandatory)]
        [string] $PropertyName
    )

    if ($null -eq $InputObject) {
        return $null
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        foreach ($key in $InputObject.Keys) {
            if ($key -ieq $PropertyName) {
                return $InputObject[$key]
            }

            $nested = Get-DeepPropertyValue -InputObject $InputObject[$key] -PropertyName $PropertyName
            if ($null -ne $nested) {
                return $nested
            }
        }

        return $null
    }

    if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
        foreach ($item in $InputObject) {
            $nested = Get-DeepPropertyValue -InputObject $item -PropertyName $PropertyName
            if ($null -ne $nested) {
                return $nested
            }
        }

        return $null
    }

    foreach ($property in $InputObject.PSObject.Properties) {
        if ($property.Name -ieq $PropertyName) {
            return $property.Value
        }

        $nested = Get-DeepPropertyValue -InputObject $property.Value -PropertyName $PropertyName
        if ($null -ne $nested) {
            return $nested
        }
    }

    return $null
}

$callbackUriPath = Get-DeepPropertyValue -InputObject $triggerBody -PropertyName "callbackUriPath"
$stageInstanceId = Get-DeepPropertyValue -InputObject $triggerBody -PropertyName "customExtensionStageInstanceId"

$assignmentRequestIdFromBody = Get-DeepPropertyValue -InputObject $triggerBody -PropertyName "accessPackageAssignmentRequestId"

if (-not $assignmentRequestIdFromBody) {
    $assignmentRequestIdFromBody = Get-DeepPropertyValue -InputObject $triggerBody -PropertyName "id"
}

[pscustomobject]@{
    CallbackUriPath = $callbackUriPath
    CustomExtensionStageInstanceId = $stageInstanceId
    AssignmentRequestIdFromBody = $assignmentRequestIdFromBody
}
```

**4. Check Whether CallbackUriPath Points To The Request Being Resumed**

```pwsh
$assignmentRequestIdFromCallbackPath = $null

if ($callbackUriPath -match "/accessPackageAssignmentRequests/([^/]+)/resume") {
    $assignmentRequestIdFromCallbackPath = $Matches[1]
}

[pscustomobject]@{
    CallbackUriPath = $callbackUriPath
    AssignmentRequestIdFromCallbackPath = $assignmentRequestIdFromCallbackPath
    AssignmentRequestIdFromBody = $assignmentRequestIdFromBody
    StageInstanceId = $stageInstanceId
    HasCallbackUriPath = -not [string]::IsNullOrWhiteSpace($callbackUriPath)
    HasStageInstanceId = -not [string]::IsNullOrWhiteSpace($stageInstanceId)
}
```

**5. Check The Assignment Request Is Actually Waiting For Callback**

This is the big one. The Learn docs say resume only works when `requestStatus` is `WaitingForCallback`.

```pwsh
$assignmentRequestId = $assignmentRequestIdFromCallbackPath

if (-not $assignmentRequestId) {
    throw "Could not extract accessPackageAssignmentRequestId from callbackUriPath."
}

$assignmentRequest = Invoke-MgGraphRequest `
    -Method GET `
    -Uri "https://graph.microsoft.com/beta/identityGovernance/entitlementManagement/accessPackageAssignmentRequests/$assignmentRequestId"

$assignmentRequest | Select-Object `
    id,
    requestType,
    requestStatus,
    createdDateTime,
    completedDateTime,
    accessPackageAssignment,
    accessPackage
```

Quick pass/fail:

```pwsh
if ($assignmentRequest.requestStatus -eq "WaitingForCallback") {
    "OK: Assignment request is WaitingForCallback."
}
else {
    "NOT OK: Assignment request status is '$($assignmentRequest.requestStatus)', so /resume will likely fail."
}
```

**6. Check The Resume URL You Should Use**

For the Logic App HTTP action, the URL should be built from the callback path from the trigger payload:

```pwsh
$resumeUri = "https://graph.microsoft.com/beta$callbackUriPath"

[pscustomobject]@{
    ResumeUri = $resumeUri
    ShouldEndWithResume = $resumeUri -match "/resume$"
    UsesCallbackUriPath = $resumeUri -eq "https://graph.microsoft.com/beta$callbackUriPath"
}
```

**7. Build The Resume Body Without Sending It**

```pwsh
$resumeBody = @{
    source = "2ProvisionAdmin"
    type = "microsoft.graph.accessPackageCustomExtensionStage.assignmentRequestCreated"
    data = @{
        "@odata.type" = "microsoft.graph.accessPackageAssignmentRequestCallbackData"
        stage = "assignmentRequestCreated"
        customExtensionStageInstanceId = $stageInstanceId
        customExtensionStageInstanceDetail = "Provisioning completed."
    }
}

$resumeBody | ConvertTo-Json -Depth 20
```

If your extension stage is not `assignmentRequestCreated`, change the `type` suffix and `data.stage` to match the stage in the incoming callback payload.

**8. Actually Call Resume, Only After The Checks Pass**

```pwsh
if (-not $callbackUriPath) {
    throw "Missing callbackUriPath."
}

if (-not $stageInstanceId) {
    throw "Missing customExtensionStageInstanceId."
}

if ($assignmentRequest.requestStatus -ne "WaitingForCallback") {
    throw "Assignment request is '$($assignmentRequest.requestStatus)', not WaitingForCallback. Not calling resume."
}

Invoke-MgGraphRequest `
    -Method POST `
    -Uri "https://graph.microsoft.com/beta$callbackUriPath" `
    -Body ($resumeBody | ConvertTo-Json -Depth 20) `
    -ContentType "application/json"
```

**9. Optional: Check The User-Assigned Managed Identity Exists**

```pwsh
$identityResourceId = "/subscriptions/41f018dd-427b-445f-9262-6b32b603662e/resourcegroups/entraLab/providers/Microsoft.ManagedIdentity/userAssignedIdentities/entraLabInstance"

$identity = Invoke-AzRestMethod `
    -Method GET `
    -Path "$identityResourceId?api-version=2023-01-31" |
    Select-Object -ExpandProperty Content |
    ConvertFrom-Json

$identity | Select-Object `
    name,
    location,
    @{ Name = "principalId"; Expression = { $_.properties.principalId } },
    @{ Name = "clientId"; Expression = { $_.properties.clientId } },
    id
```

The most telling result will be block 5. If the request is not `WaitingForCallback`, then `InvalidCustomExtensionStageInstanceId` is expected even when the ID is non-empty.