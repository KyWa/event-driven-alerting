# Event Driven Tekton
Technologies used:
- OpenShift Pipelines (Tekton)
- Prometheus (AlertManager)
- OpenShift/Kubernetes

## Goal
Have `AlertManager` send alerts to a webhook run by an `EventListener` through OpenShift Pipelines to act upon OpenShift/Kubernetes events.

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
