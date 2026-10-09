// ---------------------------------------------------------------------------
// Module: identity-rbac.bicep
// Assigns storage data-plane roles to the Function App managed identity.
// ---------------------------------------------------------------------------

@description('The name of the storage account to scope role assignments to.')
param storageAccountName string

@description('The principal ID of the Function App system-assigned managed identity.')
param functionAppPrincipalId string

// --- Existing Storage Account Reference ---
resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' existing = {
  name: storageAccountName
}

// --- Role Definitions ---
// Each entry maps a built-in role name to its well-known GUID.
var storageRoles = [
  {
    name: 'Storage Blob Data Owner'
    id: 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
  }
  {
    name: 'Storage Queue Data Contributor'
    id: '974c5e8b-45b9-4653-ba55-5f855dd0fb88'
  }
  {
    name: 'Storage Table Data Contributor'
    id: '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3'
  }
]

// --- Role Assignments (looped) ---
resource roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for role in storageRoles: {
    name: guid(storageAccount.id, functionAppPrincipalId, role.id)
    scope: storageAccount
    properties: {
      roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', role.id)
      principalId: functionAppPrincipalId
      principalType: 'ServicePrincipal'
    }
  }
]
