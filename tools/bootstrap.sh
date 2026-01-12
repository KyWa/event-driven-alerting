#!/usr/bin/env bash

create_events_ns(){
  oc get namespace events &> /dev/null

  if [ $? -eq 0 ];then
    echo "Namespace exists... Skipping"
  else
    oc create namespace events
  fi
}

configure_alertmanager(){
  ALERTMANAGER_CONFIG=`echo -n "$(cat ../manifests/alertmanager-main.yaml)" | base64 -w0`
  oc patch secret -n openshift-monitoring alertmanager-main --type=merge -p '{"data":{"alertmanager.yaml":"'${ALERTMANAGER_CONFIG}'"}}'
}

setup_events_ns(){
  ### Check for events to generate
  ALERTS=`ls -d ../manifests/*/ | cut -d "/" -f 3`
  i=0
  echo "Below are options to setup an EventListener for testing"
  for a in $ALERTS;do
    echo "$((i += 1)) $a"
  done
  echo "Which EventListener would you like to create? "
  read answer
  echo ""

  case $answer in
    1)
      echo "Deploying for AlertmanagerClusterFailedToSendAlerts"
      oc create -n events -f ../manifests/AlertmanagerClusterFailedToSendAlerts/
      ;;
    2)
      echo "Deploying for IngressWithoutClassName"
      oc create -n events -f ../manifests/IngressWithoutClassName/
      ;;
    3)
      echo "Deploying for PodDisruptionBudgetAtLimit"
      oc create -n events -f ../manifests/PodDisruptionBudgetAtLimit/
      ;;
    all)
      echo "Deploying all"
      for i in $ALERTS;do oc create -n events -f ../manifests/$i/;done
      ;;
    *)
      echo "Not a valid option. Exiting"
      exit
      ;;
  esac
}

create_events_ns
setup_events_ns
#configure_alertmanager
