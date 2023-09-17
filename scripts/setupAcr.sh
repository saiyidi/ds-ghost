ACR_RG='drs-container-rg'
ACR_NAME='drsregistry'

# create a resource group
az group create -n $ACR_RG -l WestEurope

# create a container registry
az acr create -g $ACR_RG -n $ACR_NAME --sku Basic --admin-enabled true
