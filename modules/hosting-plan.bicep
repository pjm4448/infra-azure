// ---------------------------------------------------------------------------
// Module: hosting-plan.bicep
// Deploys a Flex Consumption (FC1) App Service Plan for Linux.
// ---------------------------------------------------------------------------

@description('The workload identifier used in resource naming.')
param workload string

@description('The deployment environment short name.')
@allowed(['dev', 'test', 'prod'])
param environment string

@description('The Azure region for resource deployment.')
param location string

// --- Naming ---
var planName = 'asp-${workload}-${environment}-aue-01'

// --- Flex Consumption Plan ---
resource hostingPlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: planName
  location: location
  kind: 'functionapp'
  sku: {
    tier: 'FlexConsumption'
    name: 'FC1'
  }
  properties: {
    reserved: true
  }
}

// --- Outputs ---
@description('The hosting plan resource ID.')
output planId string = hostingPlan.id
