@description('The name of the Managed Cluster resource.')
param clusterName string = 'aks-flux'

@description('The location of the Managed Cluster resource.')
param location string = resourceGroup().location

@description('Disk size (in GB) to provision for each of the agent pool nodes. This value ranges from 0 to 1023. Specifying 0 will apply the default disk size for that agentVMSize.')
@minValue(0)
@maxValue(1023)
param osDiskSizeGB int = 0

@description('The number of nodes for the cluster.')
@minValue(1)
@maxValue(50)
param agentCount int = 1

@description('The size of the Virtual Machine.')
param agentVMSize string = 'standard_d2s_v3'

resource aks 'Microsoft.ContainerService/managedClusters@2023-11-01' = {
  name: clusterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: clusterName
    agentPoolProfiles: [
      {
        name: 'agentpool'
        osDiskSizeGB: osDiskSizeGB
        count: agentCount
        vmSize: agentVMSize
        osType: 'Linux'
        mode: 'System'
      }
    ]
  }
}

resource fluxExtension 'Microsoft.KubernetesConfiguration/extensions@2021-09-01' = {
  name: 'flux'
  scope: aks
  properties: {
    extensionType: 'microsoft.flux'
    autoUpgradeMinorVersion: true
    releaseTrain: 'Stable'
  }
}

resource fluxConfig 'Microsoft.KubernetesConfiguration/fluxConfigurations@2021-11-01-preview' = {
  name: 'gitops-demo'
  scope: aks
  dependsOn: [
    fluxExtension
  ]
  properties: {
    scope: 'cluster'
    namespace: 'default'
    sourceKind: 'GitRepository'
    suspend: false
    gitRepository: {
      url: 'https://github.com/fluxcd/flux2-kustomize-helm-example'
      timeoutInSeconds: 600
      syncIntervalInSeconds: 600
      localAuthRef: 'gitops-demo-protected-parameters'
      repositoryRef: {
        branch: 'main'
      }
    }
  }
}

output controlPlaneFQDN string = aks.properties.fqdn
