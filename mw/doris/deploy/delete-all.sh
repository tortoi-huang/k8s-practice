#!/bin/sh

script_dir="$(dirname "$0")"
kubectl delete -f $script_dir/02doris-be.yaml
kubectl delete -f $script_dir/01doris-fe.yaml

kubectl delete pvc -l app.doris.cluster=doriscluster-helm