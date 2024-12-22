param botIdentityName string

param location string = resourceGroup().location

resource appServiceIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  location: location
  name: botIdentityName
}

output appIdentityId string = appServiceIdentity.id
output aspIdentityName string = appServiceIdentity.name
output aspIdentityPrincipalId string = appServiceIdentity.properties.principalId
