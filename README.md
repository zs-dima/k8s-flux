# k3s monitoring stack

### k3s

```shell
sudo apt-get update && sudo apt-get upgrade -y

export DOMAIN=domain.com \
export EMAIL=mail@domain.com \
export RANCHER_PASSWORD=123

kubectl create secret docker-registry docker-registry-key \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=[DockerHub username] \
  --docker-password=[DockerHub access token] \
  --docker-email=[email address]

curl -sfL https://get.k3s.io | sh -s - --disable=traefik

nano ~/.bashrc
# Add following line at the end of the file:
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
source ~/.bashrc
```


### Helm

```shell
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update && sudo apt-get install helm
```


### cert-manager

```shell
helm repo add jetstack https://charts.jetstack.io
helm repo update && helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.13.2 \
  --set installCRDs=true

curl -L https://github.com/alenkacz/cert-manager-verifier/releases/download/v0.3.0/cert-manager-verifier_0.3.0_Linux_arm64.tar.gz -o cm-verifier.tar.gz
tar -zxvf cm-verifier.tar.gz
chmod +x cm-verifier
./cm-verifier

kubectl create secret generic cloudflare-api-token-secret \
--from-literal=api-token='{TOKEN}' \
--namespace cert-manager
```


### Traefik

```shell
kubectl create ns traefik
envsubst < ./core/traefik.yaml | kubectl apply -f -

htpasswd -c ./core/auth dima
kubectl create secret generic basic-auth-secret \
--from-literal=auth='{USER:PWD}' \
-n traefik

envsubst < ./core/cert-manager.yaml | kubectl apply -f -
envsubst < ./core/traefik-middleware.yaml | kubectl apply -f -

helm repo add traefik https://traefik.github.io/charts && helm repo update
envsubst < ./core/traefik-values.yaml | helm install -n traefik traefik traefik/traefik \
  --set image.tag=v3.0 \
  -f -
```


### Rancher

```shell
kubectl create namespace cattle-system
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest && helm repo update
envsubst < ./core/rancher-values.yaml | helm install -n cattle-system rancher rancher-latest/rancher \
  --version 2.8.0-rc3 \
  -f -
```


### Longhorn
```shell
kubectl create namespace longhorn
helm repo add longhorn https://charts.longhorn.io && helm repo update
helm install longhorn longhorn/longhorn -n longhorn --create-namespace

cat ./core/longhorn-ingress.yaml | envsubst | kubectl apply -f -
```


### Heimdall

```shell
cat ./core/heimdall.yaml | envsubst | kubectl apply -f -
```