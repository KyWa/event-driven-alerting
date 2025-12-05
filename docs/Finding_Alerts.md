# How to go through alerts

Start parsing alerts from `alerts.json` with `jq` like so:


## Prometheus Rules Details
```sh
### Get all of the Prometheus rules for a cluster
oc get prometheusrules -A -o json > prometheusrules.json

### Determine rules for a specific alert
jq -r '.items[].spec.groups[].rules[] | select(.alert == "AlertmanagerClusterFailedToSendAlerts")' prometheusrules.json
```

## Querying the generated alerts file
### Get AlertNames currently Firing
```sh
jq -r '.data.alerts[] | select(.state == "firing") .labels.alertname' alerts.json | sort -u
```
