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

## Example Alerts from AlertManager
```json
{
  "labels": {
    "alertname": "PodDisruptionBudgetAtLimit",
    "namespace": "some-namespace",
    "poddisruptionbudget": "some-poddisruptionbudget",
    "severity": "warning"
  },
  "annotations": {
    "description": "The pod disruption budget is at the minimum disruptions allowed level. The number of current healthy pods is equal to the desired healthy pods.",
    "runbook_url": "https://github.com/openshift/runbooks/blob/master/alerts/cluster-kube-controller-manager-operator/PodDisruptionBudgetAtLimit.md",
    "summary": "The pod disruption budget is preventing further disruption to pods."
  },
  "state": "firing",
  "activeAt": "2025-12-12T14:11:25.403750311Z",
  "value": "1e+00"
}
```

Below is targeting a Service (which was a StatefulSet)
```json
{
  "labels": {
    "alertname": "TargetDown",
    "job": "alertmanager-metrics",
    "namespace": "open-cluster-management-observability",
    "service": "alertmanager-metrics",
    "severity": "warning"
  },
  "annotations": {
    "description": "100% of the alertmanager-metrics/alertmanager-metrics targets in open-cluster-management-observability namespace have been unreachable for more than 15 minutes. This may be a symptom of network connectivity issues, down nodes, or failures within these components. Assess the health of the infrastructure and nodes running these targets and then contact support.",
    "runbook_url": "https://github.com/openshift/runbooks/blob/master/alerts/cluster-monitoring-operator/TargetDown.md",
    "summary": "Some targets were not reachable from the monitoring server for an extended period of time."
  },
  "state": "firing",
  "activeAt": "2025-10-29T00:58:32.286756891Z",
  "value": "1e+02"
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

### ArgoCDSyncAlert - User
Sometimes when changing helm charts or repos, argo may fail to sync and just needs to be forced

### TargetDown
metric pod bounces

### PodDisruptionBudgetLimit / PodDisruptionBudgetAtLimit
Patch PDB if triggered
This rule doesn't appear in a fresh HCP cluster in the `openshift-kube-controller-manager-operator` namespace

### KubePodNotReady
TODO

### `IngressWithoutClassName`
OpenShift can create usable `Routes` from an `Ingress` object, but must follow the required configuration of having the `.spec.ingressClassName` set to either `public` or `openshift-default`.

Idea:
- oc patch `ingress` -n namespace .spec.ingressClassName == openshift-default
- check for `Route` with matching Host to confirm it exists (pre / post)

### User Workload Actions
Users with custom alertrules for their applications, can utilize this to have openshift pipelines go and "do something" inside the cluster without the need for external systems.
- move away from app needing to know "what to do when X happens"

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

## Tekton YAML
```yaml
apiVersion: triggers.tekton.dev/v1beta1
kind: EventListener
metadata:
  name: alertmanager-listener
spec:
  serviceAccountName: pipeline
  triggers:
  - triggerRef: example-trigger
  
apiVersion: triggers.tekton.dev/v1beta1
kind: TriggerTemplate
metadata:
  name: example-template
spec:
  params:
  - name: alertname
  resourcetemplates:
  - apiVersion: tekton.dev/v1
    kind: PipelineRun
    metadata:
      generateName: example-
    spec:
      pipelineRef:
        name: example-pipeline
      params:
      - name: alertname
        value: "$(tt.params.alertname)"
        
apiVersion: triggers.tekton.dev/v1beta1
kind: TriggerBinding
metadata:
  name: watchdog-example
spec:
  params:
  - name: alertname
    value: "$(body.alerts[0].labels.alertname)"
