# BO1048 - Automated Event Handling with OpenShift Pipelines
Technologies used:
- OpenShift/Kubernetes
- OpenShift Pipelines (Tekton)
- Prometheus (AlertManager)

## Goal
Have `AlertManager` send alerts to a webhook run by an `EventListener` through OpenShift Pipelines to act upon OpenShift/Kubernetes events.

Bonus points/thought: Include an "if it cant fix it, open a ticket to a support team" following this guide/doc: https://www.redhat.com/en/blog/itsm-prometheus-alerts

## Prerequisites
Operator: OpenShift Pipelines
Testing in this assumes using the namespace `events`

## Example Alert from AlertManager
```json
{
  "labels": {
    "alertname": "KubeJobFailed",
    "condition": "true",
    "container": "kube-rbac-proxy-main",
    "endpoint": "https-main",
    "job": "kube-state-metrics",
    "job_name": "fa8004602e11c23123aaoijdppl2310",
    "namespace": "openshift-marketplace",
    "service": "kube-state-metrics",
    "severity": "warning"
  },
  "annotations": {
    "description": "Job openshift-marketplace/fa8004602e11c23123aaoijdppl2310 failed to complete. Removing failed job after investigation should clear this alert.",
    "summary": "Job failed to complete"
  },
  "state": "firing",
  "activeAt": "2025-07-14T18:09:14.270840147Z",
  "value": "1e+00"
}
```

## Example AlertManager Config
On OpenShift, this lives in the Secret `alertmanager-main` in the `openshift-monitoring` namespace:

```yaml
global:
  resolve_timeout: 5m
receivers:
- name: Webhooks
  webhook_configs:
  - send_resolved: false
    url: "http://el-event-driven-alerts.events.svc.cluster.local:8080"
- name: Default
route:
  group_by:
  - namespace
  group_interval: 5m
  group_wait: 30s
  receiver: Default
  repeat_interval: 12h
  routes:
  - receiver: Webhooks
```

## Presentation Examples
### Image Pull Failures
Image failing to pull for an operator in the `openshift-marketplace` namespace. We can have a `Task` that will check the events of that Job to do some of the following:
- If image pull because timeout or something similar, Do XYZ
- else; delete Job to clear Alert

### Monitor the Monitoring System | AlertManager Health
Look for the `AlertmanagerClusterFailedToSendAlerts` alert

### KubePodNotReady
TODO

### `IngressWithoutClassName`
OpenShift can create usable `Routes` from an `Ingress` object, but must follow the required configuration of having the `.spec.ingressClassName` set to either `public` or `openshift-default`.

Idea:
- oc patch `ingress` -n namespace .spec.ingressClassName == openshift-default
- check for `Route` with matching Host to confirm it exists (pre / post)

## Findings/Notes
Get alerts from cluster via:
```sh
oc -n openshift-monitoring exec -c prometheus prometheus-k8s-0 -- curl -s 'http://localhost:9090/api/v1/alerts' > alerts.json
```

Alerts that are pending may be the best candidate to act upon as those alerts have been triggered, but haven't met the next check for if it is really an issue or not. Info here on the "for" clause: https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/

Not all `alerts` have the same `labels` so be sure to verify which labels you are keying off of for your templates. `kube-state-metrics` is what houses/applies the various labels based on the topic: https://github.com/kubernetes/kube-state-metrics/tree/main/docs/metrics/workload

AlertManager Config can just have all Alerts send and not call them out specifically to allow triggering to be moved "up" in the stack. Alongside this, the `EventListener` can have additional `Triggers` appended to it as the requirements/needs grow.

Need a `Trigger` for each alert to go act upon a specific alert to be able to call a specific pipeline
- maybe find a way to trim this down so its not duplication of efforts

`.labels.resource` will show what `kind` it was (if present of course)
