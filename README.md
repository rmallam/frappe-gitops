# frappe-gitops
### Deploy argocd

helm repo add argo https://argoproj.github.io/argo-helm
helm install argocd argo/argo-cd


kubectl patch configmap argocd-cm --type merge -p '
data:
  repositories: |
    - type: helm
      name: bitnami
      enableOCI: true
      url: oci://registry-1.docker.io/bitnamicharts
'

oc apply -f cluster-pre-req-appset.yaml


### setup ingress for argocd

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

helm repo update

helm install nginx-ingress ingress-nginx/ingress-nginx --set controller.publishService.enabled=true

## mariadb

kubectl create secret generic mariadb \
    --from-literal=mariadb-root-password='foo123' \
    --from-literal=mariadb-password='foo123'
secret/mariadb-passwords created


## create digital ocean kube cluster
doctl k c c rmk8s \
  --node-pool "name=example-pool;size=s-2vcpu-2gb;count=1;auto-scale=true;min-nodes=1;max-nodes=3"

## delete digital ocean kube cluster

doctl k cluster delete rmk8s --force

