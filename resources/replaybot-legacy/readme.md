# replaybot-legacy
deployment files for the current version of replaybot

provide a secret in the cluster as follows:

`echo -n 'secret-value' | base64`

```
apiVersion: v1
kind: Secret
metadata:
  name: replaybot-secrets
  namespace: replaybot-legacy
type: Opaque
data:
  NEW_RELIC_LICENSE_KEY: [encoded key]
  BOT_TOKEN: [encoded key]
  BOT_SHARED_KEY: [encoded key]
```
