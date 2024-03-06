##!/usr/bin/env sh
kubectl delete -f nginx-demo-client.yaml
kubectl delete -f nginx-demo-server.yaml
kubectl delete -f nginx-demo-cert.yaml

kubectl -n mw delete secret -l app.kubernetes.io/name=nginx-tls-demo