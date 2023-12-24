Kubernetes Cluster configuration to deploy using FluxCD.

## Installation

0. Setup k3s cluster
```shell
sudo apt-get update && sudo apt-get upgrade -y

sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d
echo 'export PATH="$PATH:./bin/"' >> ~/.bashrc
source ~/.bashrc

task init:k3s
```

1. Rename .env.example to .env and fill variables

2. Setup external secrets: [/scripts/secrets/google_cloud/README.md](https://github.com/zs-dima/monitoring-stack-k3s/tree/main/scripts/secrets/google_cloud)

3. Run task to deploy cluster
```shell
task
```

4. Check if cluster is deployed
```shell
flux get kustomizations
```


## Troubleshooting

https://fluxcd.io/flux/cheatsheets/troubleshooting/
