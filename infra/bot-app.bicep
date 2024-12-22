param appName string
param tags object
param location string = resourceGroup().location
param logAnalyticsId string
param managedIdentityName string
param appServicePlanId string
// Runtime Properties
@allowed([
  'dotnet'
  'dotnetcore'
  'dotnet-isolated'
  'node'
  'python'
  'java'
  'powershell'
  'custom'
])
param runtimeName string
param runtimeNameAndVersion string = '${runtimeName}|${runtimeVersion}'
param runtimeVersion string

// Reference Properties
param applicationInsightsName string = ''
param keyVaultName string = ''

resource botIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: managedIdentityName
}

resource app 'Microsoft.Web/sites@2022-09-01' = {
  name: appName
  location: location
  tags: union(tags, { 'azd-service-name': 'bot' })
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${botIdentity.id}': {}
    }
  }
  kind: 'app,linux'
  properties: {
    httpsOnly: true
    serverFarmId: appServicePlanId
    publicNetworkAccess: 'Enabled' //simulate locked-down network by blocking access to app site. But I need to deploy, so I open up SCM site.
    clientAffinityEnabled: false
    keyVaultReferenceIdentity: botIdentity.id
    siteConfig: {
      linuxFxVersion: runtimeNameAndVersion
      minTlsVersion: '1.2'
      alwaysOn: false
      ftpsState: 'FtpsOnly'
      cors: {
        allowedOrigins: [
          'https://portal.azure.com'
          'https://ms.portal.azure.com'
          'https://botservice.hosting.portal.azure.net'
          'https://hosting.onecloud.azure-test.net/'
        ]
      }
      webSocketsEnabled: true
      healthCheckPath: '/health'
      appSettings: [
        {
          name: 'AZURE_CLIENT_ID' // resolves user-assigned identity
          value: botIdentity.properties.clientId
        }
        {
          name: 'MicrosoftAppTenantId'
          value: botIdentity.properties.tenantId
        }
        {
          name: 'MicrosoftAppId'
          value: botIdentity.properties.clientId
        }
        {
          name: 'MicrosoftAppType'
          value: 'UserAssignedMSI'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: !empty(applicationInsightsName) ? applicationInsights.properties.ConnectionString : ''
        }
        {
          name: 'AZURE_KEY_VAULT_ENDPOINT'
          value: !empty(keyVaultName) ? keyVault.properties.vaultUri : ''
        }
      ]
    }
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = if (!(empty(keyVaultName))) {
  name: keyVaultName
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = if (!empty(applicationInsightsName)) {
  name: applicationInsightsName
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: app
  name: 'diagnostics'
  properties: {
    workspaceId: logAnalyticsId
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
      }
      {
        category: 'AppServiceAppLogs'
        enabled: true
      }
      {
        category: 'AppServiceAuditLogs'
        enabled: false
      }
      {
        category: 'AppServicePlatformLogs'
        enabled: false
      }
    ]
  }
}

output name string = app.name
output uri string = 'https://${app.properties.defaultHostName}'
