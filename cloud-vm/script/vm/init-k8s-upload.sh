#!/bin/bash

if [ ! -n "$APISERVER_ADVERTISE_ADDRESS" ]; then 
    echo "variable: APISERVER_ADVERTISE_ADDRESS not load"
    exit 1
fi

kubeadm init --control-plane-endpoint ${APISERVER_ADVERTISE_ADDRESS}:${APISERVER_DEST_PORT} --apiserver-advertise-address ${NODE_IP} --upload-certs
