##!/usr/bin/env sh

kubectl exec -it pod/vault-server-0 -n mw -- vault operator init > key0.txt
cat key0.txt|grep Unseal|\sed -E 's/^.*Unseal Key [1-5]\: ([0-9a-zA-Z+\/=]+).*/kubectl exec -it pod\/vault-server-0 -n mw -- vault operator unseal \1/g'|sh


kubectl exec -it pod/vault-server-1 -n mw -- vault operator raft join http://vault-server-0.vault-server-headless:8200
cat key0.txt|grep Unseal|\sed -E 's/^.*Unseal Key [1-5]\: ([0-9a-zA-Z+\/=]+).*/kubectl exec -it pod\/vault-server-1 -n mw -- vault operator unseal \1/g'|sh


kubectl exec -it pod/vault-server-2 -n mw -- vault operator raft join http://vault-server-0.vault-server-headless:8200
cat key0.txt|grep Unseal|\sed -E 's/^.*Unseal Key [1-5]\: ([0-9a-zA-Z+\/=]+).*/kubectl exec -it pod\/vault-server-2 -n mw -- vault operator unseal \1/g'|sh

