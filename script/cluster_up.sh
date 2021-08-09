#!/bin/bash

# terraform -chdir=infra/aws init
# terraform -chdir=infra/aws apply
eval $(terraform -chdir=infra/aws output -json | jq -r 'to_entries | .[] | "export " + (.key | ascii_upcase) + "=" + .value.value')
aws eks update-kubeconfig --name ${CLUSTER_NAME} --region ${AWS_REGION} --alias challenge
kubectl -n kube-system patch deploy coredns --type json -p='[{"op": "remove", "path": "/spec/template/metadata/annotations"}]'
cat infra/k8s/ingress-controller/* | envsubst | kubectl apply -f -
kubectl kustomize infra/k8s/application | kubectl apply -f -
