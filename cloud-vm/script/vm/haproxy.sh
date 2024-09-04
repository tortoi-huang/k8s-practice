#!/bin/bash


# 遇到错误时停止执行后续语句
set -e

script_dir="$(dirname "$0")"
source $script_dir/env.profile
if [ ! -n "$APISERVER_DEST_PORT" ]; then 
    echo "variable: APISERVER_DEST_PORT not load"
    exit 1
fi

sudo apt install haproxy -y

sudo tee /etc/haproxy/haproxy.cfg <<-EOF
# /etc/haproxy/haproxy.cfg
#---------------------------------------------------------------------
# Global settings
#---------------------------------------------------------------------
global
    log stdout format raw local0
    daemon

#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 1
    timeout http-request    10s
    timeout queue           20s
    timeout connect         5s
    timeout client          35s
    timeout server          35s
    timeout http-keep-alive 10s
    timeout check           10s

#---------------------------------------------------------------------
# apiserver frontend which proxys to the control plane nodes
#---------------------------------------------------------------------
frontend apiserver
    bind *:${APISERVER_DEST_PORT}
    mode tcp
    option tcplog
    default_backend apiserverbackend

#---------------------------------------------------------------------
# round robin balancing for apiserver
#---------------------------------------------------------------------
backend apiserverbackend
    option httpchk

    http-check connect ssl
    http-check send meth GET uri /healthz
    http-check expect status 200

    mode tcp
    balance     roundrobin
    
    server 1 ${CONTROL_NODE1}:${APISERVER_SRC_PORT} check verify none
    server 2 ${CONTROL_NODE2}:${APISERVER_SRC_PORT} check verify none
    server 3 ${CONTROL_NODE3}:${APISERVER_SRC_PORT} check verify none
EOF

sudo systemctl restart haproxy