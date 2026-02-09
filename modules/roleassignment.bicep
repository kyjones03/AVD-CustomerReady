// ──────────────────────────────────────────────
// Role Assignment Module — AVD Service Principal
// Desktop Virtualization Power On Contributor
// ──────────────────────────────────────────────

// AVD Service Principal (well-known ID)
param avdServicePrincipalId string = '7e4875e1-a13b-4d6e-8fb9-116478ee919d'

// Desktop Virtualization Power On Contributor role definition
var powerOnContributorRoleId = '489581de-a3bd-480d-9518-53dea7416b33'

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, avdServicePrincipalId, powerOnContributorRoleId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', powerOnContributorRoleId)
    principalId: avdServicePrincipalId
    principalType: 'ServicePrincipal'
  }
}

output roleAssignmentId string = roleAssignment.id
