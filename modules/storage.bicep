// ---------------------------------------------------------------------------
// Module: storage.bicep
// Deploys a keyless Storage Account and the Flex Consumption deployment
// package container.
// ---------------------------------------------------------------------------

@description('The workload identifier used in resource naming.')
param workload string

@description('The deployment environment short name.')
@allowed(['dev', 'test', 'prod'])
param environment string

@description('The Azure region for resource deployment.')
param location string

// --- Naming (storage accounts: ≤24 chars, lowercase alphanumeric only) ---
var storageAccountName = 'st${workload}${environment}aue01'

// --- Storage Account ---
resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    supportsHttpsTrafficOnly: true
    defaultToOAuthAuthentication: true
  }
}

// --- Blob Services (required parent for container) ---
resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2024-01-01' = {
  parent: storageAccount
  name: 'default'
}

// --- Deployment Package Container ---
resource deploymentContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2024-01-01' = {
  parent: blobServices
  name: 'deploymentpackage'
  properties: {
    publicAccess: 'None'
  }
}

// --- Outputs ---
@description('The storage account name (used in AzureWebJobsStorage__accountName).')
output storageAccountName string = storageAccount.name

@description('The blob endpoint URL (used in deployment storage configuration).')
output storageAccountBlobEndpoint string = storageAccount.properties.primaryEndpoints.blob

@description('The storage account resource ID (used for RBAC scope).')
output storageAccountId string = storageAccount.id
