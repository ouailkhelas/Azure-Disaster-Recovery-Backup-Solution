param location string = resourceGroup().location
param environment string = 'dev'
param vmName string = 'dr-vm-primary'
param vmSize string = 'Standard_B2s'
param adminUsername string = 'azureuser'
@secure()
param adminPassword string
param vnetName string = 'dr-vnet'
param subnetName string = 'dr-subnet'
param recoveryVaultName string = 'recovery-vault'
param backupPolicyName string = 'daily-backup-policy'
param secondaryLocation string = 'westus'

var uniqueSuffix = uniqueString(resourceGroup().id)
var vnetAddressPrefix = '10.0.0.0/16'
var subnetAddressPrefix = '10.0.1.0/24'
var nicName = '${vmName}-nic'
var pipName = '${vmName}-pip'
var nsgName = '${vmName}-nsg'
var osDiskName = '${vmName}-osdisk'

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: '${vnetName}-${uniqueSuffix}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
        }
      }
    ]
  }
  tags: {
    environment: environment
    project: 'DisasterRecovery'
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: '${nsgName}-${uniqueSuffix}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowRDP'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowSSH'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 101
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowHTTP'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 102
          direction: 'Inbound'
        }
      }
    ]
  }
  tags: {
    environment: environment
    project: 'DisasterRecovery'
  }
}

resource pip 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: '${pipName}-${uniqueSuffix}'
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  tags: {
    environment: environment
    project: 'DisasterRecovery'
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: '${nicName}-${uniqueSuffix}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${vnet.id}/subnets/${subnetName}'
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pip.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg.id
    }
  }
  tags: {
    environment: environment
    project: 'DisasterRecovery'
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: '${vmName}-${uniqueSuffix}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        name: '${osDiskName}-${uniqueSuffix}'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
  tags: {
    environment: environment
    project: 'DisasterRecovery'
  }
}

resource vault 'Microsoft.RecoveryServices/vaults@2021-07-01' = {
  name: '${recoveryVaultName}-${uniqueSuffix}'
  location: location
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }
  tags: {
    environment: environment
    project: 'DisasterRecovery'
  }
}

resource backupPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2021-07-01' = {
  parent: vault
  name: backupPolicyName
  properties: {
    backupManagementType: 'AzureIaasVM'
    instantRpRetentionRangeInDays: 5
    schedulePolicy: {
      schedulePolicyType: 'SimpleSchedulePolicy'
      scheduleRunFrequency: 'Daily'
      scheduleRunTimes: [
        '2023-01-01T02:00:00Z'
      ]
      scheduleWeeklyFrequency: 0
    }
    retentionPolicy: {
      retentionPolicyType: 'LongTermRetentionPolicy'
      dailySchedule: {
        retentionTimes: [
          '2023-01-01T02:00:00Z'
        ]
        retentionDuration: {
          count: 30
          durationType: 'Days'
        }
      }
      weeklySchedule: {
        daysOfTheWeek: [
          'Sunday'
        ]
        retentionTimes: [
          '2023-01-01T02:00:00Z'
        ]
        retentionDuration: {
          count: 4
          durationType: 'Weeks'
        }
      }
      monthlySchedule: {
        retentionScheduleFormatType: 'Weekly'
        retentionScheduleWeekly: {
          daysOfTheWeek: [
            'Sunday'
          ]
          weeksOfTheMonth: [
            'First'
          ]
        }
        retentionTimes: [
          '2023-01-01T02:00:00Z'
        ]
        retentionDuration: {
          count: 12
          durationType: 'Months'
        }
      }
      yearlySchedule: {
        retentionScheduleFormatType: 'Weekly'
        monthsOfYear: [
          'January'
        ]
        retentionScheduleWeekly: {
          daysOfTheWeek: [
            'Sunday'
          ]
          weeksOfTheMonth: [
            'First'
          ]
        }
        retentionTimes: [
          '2023-01-01T02:00:00Z'
        ]
        retentionDuration: {
          count: 5
          durationType: 'Years'
        }
      }
    }
    timeZone: 'UTC'
  }
}

resource backupItem 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2021-07-01' = {
  name: '${vault.name}/Azure/IaasVMContainer;iaasvmcontainerv2;${resourceGroup().name};${vm.name}/vm;iaasvmcontainerv2;${resourceGroup().name};${vm.name}'
  properties: {
    protectedItemType: 'Microsoft.Compute/virtualMachines'
    sourceResourceId: vm.id
    policyId: backupPolicy.id
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: 'kv${uniqueSuffix}'
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: reference(vm.id, '2021-03-01', 'Full').identity.principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
  }
  tags: {
    environment: environment
    project: 'DisasterRecovery'
  }
}

output vmId string = vm.id
output vmName string = vm.name
output publicIpAddress string = pip.properties.ipAddress
output vnetId string = vnet.id
output vaultId string = vault.id
output vaultName string = vault.name
output backupPolicyId string = backupPolicy.id
output keyVaultId string = keyVault.id
output keyVaultName string = keyVault.name
