#!/bin/bash

eval $(terraform -chdir=infra/aws output -json | jq -r 'to_entries | .[] | "export " + (.key | ascii_upcase) + "=" + .value.value')
kubectl kustomize infra/k8s/application | kubectl delete -f -
cat infra/k8s/ingress-controller/* | envsubst | kubectl delete -f -
terraform -chdir=infra/aws destroy
