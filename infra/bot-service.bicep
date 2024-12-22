param botName string
param botDisplayName string
param botIdentityName string
param hostName string
param logAnalyticsId string
param appInsightsInstrumentationKey string

resource botIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: botIdentityName
}

resource bot 'Microsoft.BotService/botServices@2022-09-15' = {
  name: botName
  location: 'global'
  kind: 'sdk'
  properties: {
    displayName: botDisplayName
    msaAppType: 'UserAssignedMSI'
    msaAppMSIResourceId: botIdentity.id
    msaAppId: botIdentity.properties.clientId
    msaAppTenantId: botIdentity.properties.tenantId
    endpoint: '${hostName}/api/messages'
    developerAppInsightKey: appInsightsInstrumentationKey
  }
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: bot
  name: 'diagnostics'
  properties: {
    workspaceId: logAnalyticsId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}
