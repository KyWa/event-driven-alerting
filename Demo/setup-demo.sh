#!/usr/bin/env bash

## OpenShift Pipelines Operator
oc apply -f openshift-pipelines/

## User Application Namespace
oc apply -f bad-pdb-user/

## EventsListener Namespace 
oc apply -f events/

## OpenShift Monitoring
ALERTMANAGER_CONFIG=`echo -n "$(cat openshift-monitoring/alertmanager-main.yaml)" | base64 -w0`
oc patch secret -n openshift-monitoring alertmanager-main --type=merge -p '{"data":{"alertmanager.yaml":"'${ALERTMANAGER_CONFIG}'"}}'
