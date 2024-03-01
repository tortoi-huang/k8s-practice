##!/usr/bin/env sh

kubectl exec -it pod/vault-0 -n mw -- vault operator init > key0.txt

cat key0.txt|grep Unseal|\sed -E 's/^.*Unseal Key [1-5]\: ([0-9a-zA-Z+\/=]+).*/kubectl exec -it pod\/vault-0 -n mw -- vault operator unseal \1/g'|sh


kubectl exec -it pod/vault-1 -n mw -- vault operator init > key1.txt

cat key1.txt|grep Unseal|\sed -E 's/^.*Unseal Key [1-5]\: ([0-9a-zA-Z+\/=]+).*/kubectl exec -it pod\/vault-1 -n mw -- vault operator unseal \1/g'|sh


kubectl exec -it pod/vault-2 -n mw -- vault operator init > key2.txt

cat key2.txt|grep Unseal|\sed -E 's/^.*Unseal Key [1-5]\: ([0-9a-zA-Z+\/=]+).*/kubectl exec -it pod\/vault-2 -n mw -- vault operator unseal \1/g'|sh

