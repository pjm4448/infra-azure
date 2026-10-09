// ---------------------------------------------------------------------------
// Module: monitoring.bicep
// Deploys Log Analytics Workspace and linked Application Insights.
// ---------------------------------------------------------------------------

@description('The workload identifier used in resource naming.')
param workload string

@description('The deployment environment short name.')
@allowed(['dev', 'test', 'prod'])
param environment string

@description('The Azure region for resource deployment.')
param location string

// --- Naming ---
var suffix = '${workload}-${environment}-aue-01'
var logAnalyticsName = 'log-${suffix}'
var appInsightsName  = 'appi-${suffix}'

// --- Log Analytics Workspace ---
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// --- Application Insights (workspace-integrated) ---
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
  }
}

// --- Outputs ---
@description('The Application Insights connection string for the Function App.')
output appInsightsConnectionString string = appInsights.properties.ConnectionString
