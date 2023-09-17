# Deploying your Ghost Blog on AKS

## STEP 1:

Install ghost (in empty dir) and choose your theme (for eg: casper). Remove other dirs. 
```bash
git clone https://github.com/TryGhost/Ghost.git
```

in the post.hbs, insert this in the `<section class="article-comments gh-canvas">` :
```html
        <div id="disqus_thread"></div>
        <script>
            var disqus_config = function () {
                this.page.url = "{{url absolute="true"}}";
                this.page.identifier = "ghost-{{comment_id}}"
            };
            (function() {
            var d = document, s = d.createElement('script');
            s.src = 'https://atxlinux.disqus.com/embed.js';
            s.setAttribute('data-timestamp', +new Date());
            (d.head || d.body).appendChild(s);
            })();
        </script>
```

## STEP 2

Create a new azure container registry:
```bash
ACR_RESOURCE_GROUP=container-rg

ACR_NAME=atxlinux

az group create --name $ACR_RESOURCE_GROUP --location eastus

az acr create --resource-group $ACR_RESOURCE_GROUP --name ACR_NAME --sku Basic --admin-enabled true
```

## STEP 3:

Create a new image and inject the custom theme, pushing it to your container registry
`cd content/themes`

- this will not work because content/themes/casper is a symlink, so nothing will get copied
- use this directory instead: `ghost-test/versions/5.62.0/content/themes`

Create Dockerfile:
```bash
cat <<EOF > Dockerfile
FROM ghost:5.62.0
# copy themes/config to container
COPY casper /var/lib/ghost/current/content/themes/casper
COPY config.production.json /var/lib/ghost/config.production.json
EOF
```

Create config.production.json-

```json
{
    "url": "http://localhost:2368",
    "server": {
        "port": 2368,
        "host": "0.0.0.0"
    },
    "database": {
        "client": "sqlite3",
        "connection": {
            "filename": "/var/lib/ghost/content/data/ghost.db"
        }
    },    
    "logging": {
        "transports": [
            "file",
            "stdout"
        ]
    },
    "process": "systemd",
    "paths": {
        "contentPath": "/var/lib/ghost/content"
    }
}

```

## STEP 4:

### Create an AKS cluster using the main.bicep file. The AKS cluster has AGIC enabled which acts as loadbalancer.

```bash

export AKS_RG_NAME="drs-aks-rg"
export RG_LOCATION="westeurope"
export BICEP_FILE="main.bicep"
export ACR_NAME="drsregistry"
export AKS_CLUSTER_NAME="DSKube"

# Create the Resource Group to deploy the Webinar Environment
az group create --name $AKS_RG_NAME --location $RG_LOCATION

# Deploy AKS cluster using bicep template
az deployment group create \
  --name bicepk8sdeploy \
  --resource-group $RG_NAME \
  --template-file $BICEP_FILE
```

## Get credentials
```bash
az aks get-credentials -g $AKS_RG_NAME -n $AKS_CLUSTER_NAME
```


## STEP 5:

Give the aks cluster ability to pull images from container registry

```bash
ACR_ID=$(az acr show -n $ACR_NAME -g $ACR_RESOURCE_GROUP --query "id" --output tsv)

MG_ID=$(az identity list -g rg-aks-DSKube --query [].principalId --output tsv)

az role assignment create --assignee-object-id $MG_ID --role acrpull --scope $ACR_ID
```

## STEP 6:


```bash
##Create namespace for app:
kubectl create ns ghost
```

```bash
##create storage class using storageclass.yml-
kubectl create -f storageclass.yml
```

```bash
##create PVC using pvc.yml 
kubectl create -f pvc.yml
```

```bash
## create ghost deployment using the newly created image in ACR:
kubectl apply -f deploy-prod.yml
```

```bash
## create service for ghost app:
kubectl apply -f svc.yml
```

## STEP 7:

```bash
## create ingress:
kubectl apply -f ingress.yml 
```

  
```bash
kubectl get ing -n ghost
```
- add this IP address to the DNS zone as an A record