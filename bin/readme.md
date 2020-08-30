# vpn setup scripts
taken from https://github.com/suda/k8s-ovpn-chart

* run `bin/setup-vpn` to setup the vpn for the first time. your client config will be placed in `private/client.ovpn`. set the `CLIENT_NAME` environment variable to customize the name used
* to add a new client, run `CLIENT_NAME=some_new_client bin/add-client`, and the new client configuration will be placed in `private/some_new_client.ovpn`
