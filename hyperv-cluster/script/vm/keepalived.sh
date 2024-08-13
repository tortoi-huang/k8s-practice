#!/bin/bash

# 遇到错误时停止执行后续语句
set -e

if [ ! -n "$LOADBALANCE_VIP" ]; then 
    echo "'$script_dir/env.profile' not load"
    exit 1
fi

# 健康检查服务
sudo tee /etc/keepalived/check_apiserver.sh <<-EOF
#!/bin/sh

errorExit() {
    echo "*** $*" 1>&2
    exit 1
}

curl -sfk --max-time 2 https://localhost:${APISERVER_SRC_PORT}/healthz -o /dev/null || errorExit "Error GET https://localhost:${APISERVER_SRC_PORT}/healthz"
EOF

sudo chmod +x /etc/keepalived/check_apiserver.sh

# 生成 keepalived 配置文件
control_nodes="${CONTROL_NODE1} ${CONTROL_NODE2} ${CONTROL_NODE3}"
unicast_peers="${control_nodes/$NODE_IP/}"
unicast_1=$(awk '{print $1}' <<< $unicast_peers)
unicast_2=$(awk '{print $2}' <<< $unicast_peers)

if [ "$CONTROL_NODE1" != "$NODE_IP" ]; then
	v_state="BACKUP"
	v_priority="101"
else
	v_state="MASTER"
    v_priority="102"
fi
sudo tee /etc/keepalived/keepalived.conf <<-EOF
! /etc/keepalived/keepalived.conf
! Configuration File for keepalived
global_defs {
    router_id LVS_DEVEL
}
vrrp_script check_apiserver {
  script "/etc/keepalived/check_apiserver.sh"
  interval 3
  weight -2
  fall 10
  rise 2
}

vrrp_instance VI_1 {
    state ${v_state} 
    interface eth0
    virtual_router_id 51
    priority ${v_priority} 
    authentication {
        auth_type PASS
        auth_pass 42
    }
    unicast_src_ip ${NODE_IP}/24
    unicast_peer {
        ${unicast_1}/24
        ${unicast_2}/24
    }
    virtual_ipaddress {
        ${LOADBALANCE_VIP}/24
    }
    track_script {
        check_apiserver
    }
}
EOF

sudo systemctl restart keepalived