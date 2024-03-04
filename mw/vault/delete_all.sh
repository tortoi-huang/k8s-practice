##!/usr/bin/env sh
kubectl delete -f helm-vault-raft-values-0.27.0.yaml

# kubectl -n mw delete pvc data-vault-0
# kubectl -n mw delete pvc data-vault-1
# kubectl -n mw delete pvc data-vault-2

kubectl -n mw get pvc|grep data-vault|awk '{print $1}'|sed -E 's/^/kubectl -n mw delete pvc\//g'|sh