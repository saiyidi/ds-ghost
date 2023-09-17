// params
@description('The DNS prefix to use with hosted Kubernetes API server FQDN.')
param dnsPrefix string = 'aks'

@description('The name of the Managed Cluster resource.')
param clusterName string = 'DSKube'

@description('Specifies the Azure location where the key vault should be created.')
param location string = resourceGroup().location

@description('Availability zones to use for the cluster nodes')
param availabilityZones array = [
  '1'
  '2'
  '3'
]

@description('Allow the cluster to auto scale to the max node count')
param enableAutoScaling bool = true

@minValue(1)
@maxValue(50)
@description('The number of nodes for the cluster. 1 Node is enough for Dev/Test and minimum 3 nodes, is recommended for Production')
param agentCount int = 1

@description('The size of the Virtual Machine.')
param agentVMSize string = 'Standard_B2s'

// vars
var kubernetesVersion = '1.27.3'
var subnetRef = '${vn.id}/subnets/${subnetName}'
var addressPrefix = '20.0.0.0/16'
var subnetName = 'Subnet01'
var subnetPrefix = '20.0.0.0/24'
var virtualNetworkName = 'AKSVNET01'
var nodeResourceGroup = 'rg-${dnsPrefix}-${clusterName}'
var tags = {
  environment: 'production'   
}
var agentPoolName = 'agentpool1'

// Azure virtual network
resource vn 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: virtualNetworkName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
        }
      }
    ]
  }
}

// Azure kubernetes service
resource aks 'Microsoft.ContainerService/managedClusters@2020-09-01' = {
  name: clusterName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: kubernetesVersion
    enableRBAC: true
    dnsPrefix: dnsPrefix
    agentPoolProfiles: [
      {
        name: agentPoolName
        count: agentCount
        mode: 'System'
        enableAutoScaling: enableAutoScaling
        availabilityZones: availabilityZones
        vmSize: agentVMSize
        type: 'AvailabilitySet'
        osType: 'Linux'        
        vnetSubnetID: subnetRef
      }
    ]
    servicePrincipalProfile: {
      clientId: 'msi'
    }
    nodeResourceGroup: nodeResourceGroup
    networkProfile: {
      networkPlugin: 'azure'
      loadBalancerSku: 'standard'
    }
  }
}

output id string = aks.id
output apiServerAddress string = aks.properties.fqdn
