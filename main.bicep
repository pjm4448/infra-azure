// ---------------------------------------------------------------------------
// Orchestrator: main.bicep
// Subscription-scoped deployment that provisions all resources for a single
// environment of the pjmcore workload.
// ---------------------------------------------------------------------------
targetScope = 'subscription'

// === Parameters ============================================================

@description('The deployment environment short name.')
@allowed(['dev', 'test', 'prod'])
param environment string

@description('The Azure region for all resources.')
param location string

@description('The workload identifier used in resource naming.')
param workload string

@description('Maximum instance count for Flex Consumption scaling.')
param maximumInstanceCount int

@description('Memory in MB allocated per Flex Consumption instance.')
@allowed([2048, 4096])
param instanceMemoryMB int

// === Variables =============================================================

var rgName = 'rg-${workload}-${environment}-aue-01'

// === Resource Group ========================================================

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgName
  location: location
}

// === Module Deployments ====================================================

// 1. Monitoring (no dependencies — can deploy in parallel with storage and plan)
module monitoring 'modules/monitoring.bicep' = {
  scope: rg
  name: 'deploy-monitoring'
  params: {
    workload: workload
    environment: environment
    location: location
  }
}

// 2. Storage (no dependencies — can deploy in parallel with monitoring and plan)
module storage 'modules/storage.bicep' = {
  scope: rg
  name: 'deploy-storage'
  params: {
    workload: workload
    environment: environment
    location: location
  }
}

// 3. Hosting Plan (no dependencies — can deploy in parallel with monitoring and storage)
module hostingPlan 'modules/hosting-plan.bicep' = {
  scope: rg
  name: 'deploy-hosting-plan'
  params: {
    workload: workload
    environment: environment
    location: location
  }
}

// 4. Function App (depends on monitoring, storage, and hosting plan)
module functionApp 'modules/function-app.bicep' = {
  scope: rg
  name: 'deploy-function-app'
  params: {
    workload: workload
    environment: environment
    location: location
    hostingPlanId: hostingPlan.outputs.planId
    storageAccountName: storage.outputs.storageAccountName
    storageAccountBlobEndpoint: storage.outputs.storageAccountBlobEndpoint
    appInsightsConnectionString: monitoring.outputs.appInsightsConnectionString
    maximumInstanceCount: maximumInstanceCount
    instanceMemoryMB: instanceMemoryMB
  }
}

// 5. Identity & RBAC (depends on function app and storage)
module identityRbac 'modules/identity-rbac.bicep' = {
  scope: rg
  name: 'deploy-identity-rbac'
  params: {
    storageAccountName: storage.outputs.storageAccountName
    functionAppPrincipalId: functionApp.outputs.functionAppPrincipalId
  }
}
