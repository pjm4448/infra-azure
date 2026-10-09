// ---------------------------------------------------------------------------
// Module: function-app.bicep
// Deploys a .NET 10 Isolated Worker Function App on Flex Consumption.
// ---------------------------------------------------------------------------

@description('The workload identifier used in resource naming.')
param workload string

@description('The deployment environment short name.')
@allowed(['dev', 'test', 'prod'])
param environment string

@description('The Azure region for resource deployment.')
param location string

@description('The resource ID of the Flex Consumption hosting plan.')
param hostingPlanId string

@description('The storage account name for identity-based storage binding.')
param storageAccountName string

@description('The storage account blob endpoint URL.')
param storageAccountBlobEndpoint string

@description('The Application Insights connection string.')
param appInsightsConnectionString string

@description('Maximum number of instances for Flex Consumption scaling.')
param maximumInstanceCount int

@description('Memory in MB allocated per instance.')
@allowed([2048, 4096])
param instanceMemoryMB int

// --- Naming ---
var functionAppName = 'func-${workload}-${environment}-aue-01'

// --- Function App ---
resource functionApp 'Microsoft.Web/sites@2024-04-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: hostingPlanId
    httpsOnly: true
    functionAppConfig: {
      deployment: {
        storage: {
          type: 'blobContainer'
          value: '${storageAccountBlobEndpoint}deploymentpackage'
          authentication: {
            type: 'SystemAssignedIdentity'
          }
        }
      }
      scaleAndConcurrency: {
        maximumInstanceCount: maximumInstanceCount
        instanceMemoryMB: instanceMemoryMB
      }
      runtime: {
        name: 'dotnet-isolated'
        version: '10.0'
      }
    }
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage__accountName'
          value: storageAccountName
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
      ]
    }
  }
}

// --- Outputs ---
@description('The system-assigned managed identity principal ID.')
output functionAppPrincipalId string = functionApp.identity.principalId

@description('The Function App name.')
output functionAppName string = functionApp.name
