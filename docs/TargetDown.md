```yaml
---
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: metrics-target-fixer
spec:
  params:
  - name: alertname
    type: string
  - name: namespace
    type: string
  - name: service
    type: string
  steps:
  - name: bounce-pods
    image: registry.access.redhat.com/ubi9/ubi
    script: |
      #!/usr/bin/env bash
      echo "Alert Triggered for $(params.alertname) in the $(params.namespace) namespace!"
      echo ""
      echo "Bouncing Pod(s) for Service $(params.service) in the $(params.namespace) namespace to attempt to fix the $(params.alertname) alert"
      ## Target Pods behind its Service/EndpointSlice
      oc get endpointslice -n "$(params.namespace)" -l kubernetes.io/service-name="$(params.service)" -o=jsonpath='{.items[*].endpoints[*]..addresses[*]}' | tr ' ' '\n' | xargs -I % oc delete pods -n "$(params.namespace)" --field-selector=status.podIP=%
```
