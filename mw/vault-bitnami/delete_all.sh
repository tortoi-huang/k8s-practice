##!/usr/bin/env sh
kubectl delete -f helm-vault-raft-values-0.10.2.yaml

# kubectl -n mw delete pvc data-vault-server-0
# kubectl -n mw delete pvc data-vault-server-1
# kubectl -n mw delete pvc data-vault-server-2
kubectl -n mw get pvc|grep data-vault-server|awk '{print $1}'|sed -E 's/^/kubectl -n mw delete pvc\//g'|sh