#!/bin/bash
# kubectl get service/doriscluster-helm-fe-service -o yaml >01.service.doriscluster-helm-fe-service.yaml
# kubectl get service/doriscluster-helm-fe-internal -o yaml >01.service.doriscluster-helm-fe-internal.yaml
# kubectl get service/doriscluster-helm-be-service -o yaml >01.service.doriscluster-helm-be-service.yaml
# kubectl get service/doriscluster-helm-be-internal -o yaml >01.service.doriscluster-helm-be-internal.yaml
# kubectl get service -l app.doris.ownerreference/name=doriscluster-helm -o yaml >01.service.yaml


kubectl get service/doriscluster-helm-fe-service -o yaml >doris.yaml
echo -e "\n---" >>doris.yaml
kubectl get service/doriscluster-helm-fe-internal -o yaml >>doris.yaml
echo -e "\n---" >>doris.yaml
kubectl get statefulset.apps/doriscluster-helm-fe -o yaml >>doris.yaml
echo -e "\n---" >>doris.yaml

kubectl get service/doriscluster-helm-be-service -o yaml >>doris.yaml
echo -e "\n---" >>doris.yaml
kubectl get service/doriscluster-helm-be-internal -o yaml >>doris.yaml
echo -e "\n---" >>doris.yaml
kubectl get statefulset.apps/doriscluster-helm-be -o yaml >>doris.yaml

