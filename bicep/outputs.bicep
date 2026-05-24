param vmId string
param vmName string
param publicIpAddress string
param vnetId string
param vaultId string
param vaultName string
param backupPolicyId string
param keyVaultId string
param keyVaultName string

output vmResourceId string = vmId
output vmDisplayName string = vmName
output vmPublicIp string = publicIpAddress
output virtualNetworkId string = vnetId
output recoveryServicesVaultId string = vaultId
output recoveryServicesVaultName string = vaultName
output backupPolicyResourceId string = backupPolicyId
output keyVaultId string = keyVaultId
output keyVaultName string = keyVaultName
