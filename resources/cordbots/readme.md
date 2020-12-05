# cordbots
provide a couple of secrets with the api keys for the bots

`echo -n 'discord-api-key' | base64`

```
apiVersion: v1
kind: Secret
metadata:
  name: terry-secrets
  namespace: terry
type: Opaque
data:
  discord: [encoded key]
---
apiVersion: v1
kind: Secret
metadata:
  name: bogs-secrets
  namespace: bogs
type: Opaque
data:
  discord: [encoded key]
```
