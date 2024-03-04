##!/usr/bin/env sh
kubectl delete -f mongodb-sharded-7.8.1.yaml

kubectl -n mw get pvc|grep datadir-mongodb-mongodb-sharded|awk '{print $1}'|sed -E 's/^/kubectl -n mw delete pvc\//g'|sh