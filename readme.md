# platform
my personal development platform
* k3s or microk8s
* external-dns to manage dns records
* cert-manager to manage ssl certificates
* flux cd to manage cluster state from the git repo
* openvpn

### deployment
copy `.env.example` to `.env` and fill in the required values, then `source .env`. copy `state.tfvars.example` to `state.tfvars` and fill in the state bucket info

run `terraform init -backend-config=state.tfvars` and then `terraform apply` to deploy. the instance will be provisioned via ansible and your kubeconfig will be downloaded to `private/kubeconfig`

### flux cd setup
you will need to add flux's ssh key to the github repo. get the public key using `bin/flux-identity` and add it to your repo at `https://github.com/${github_username}/${github_repo}/settings/keys`

### adding k8s services
commit the manifests to the repo you specified for flux cd, and it should all get picked up automatically

to take advantage of the automated dns name/cert creation you need to create an ingress and set the following annotations:
- `cert-manager.io/cluster-issuer`: "letsencrypt-staging" or "letsencrypt-prod"
- `external-dns.alpha.kubernetes.io/hostname`: your desired domain name

set `spec.tls.hosts` and `spec.rules.host` to your desired domain name

set `spec.tls.secretName` to a unique name for the secret to hold the tls cert in

an example manifest can be seen at `ansible/roles/platform/templates/example.yml`

### openvpn setup
you will need kubectl installed to set the necessary secrets for the vpn

run `bin/setup-vpn` and follow the instructions. your vpn config will be placed in `private/${hostname}client.ovpn`

if you need to use `sudo` for docker commands, you will need to use `sudo -E bin/setup-vpn` to pass through some variables from `.env`

to add a new client, run `CLIENT_NAME=some_new_client bin/add-client`, and the new client configuration will be placed in `private/${hostname}/some_new_client.ovpn`

in KDE for whatever reason the vpn connection doesnt work when imported directly into network-manager, so it must be started with `sudo openvpn --config private/${hostname}/client.ovpn`.
