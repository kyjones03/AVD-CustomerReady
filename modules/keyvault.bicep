// ──────────────────────────────────────────────
// Key Vault Module — Vault + Admin Password Secret
// ──────────────────────────────────────────────

param location string
param keyVaultName string

@secure()
param vmAdminPassword string

param currentUserObjectId string = ''

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enabledForDeployment: true
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
  }
}

resource adminPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'AVDAdminPassword'
  properties: {
    value: vmAdminPassword
  }
}

// Key Vault Secrets Officer role for current user
resource kvSecretsOfficerRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(currentUserObjectId)) {
  name: guid(keyVault.id, currentUserObjectId, 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7')
    principalId: currentUserObjectId
    principalType: 'User'
  }
}

output keyVaultId string = keyVault.id
output keyVaultUri string = keyVault.properties.vaultUri
output keyVaultName string = keyVault.name
#disable-next-line outputs-should-not-contain-secrets // This is the secret name, not the value
output adminPasswordSecretName string = adminPasswordSecret.name
