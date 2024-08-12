
script_dir="$(dirname "$0")"
source $script_dir/env.profile
if [ ! -n "$LOADBALANCE_VIP" ]; then 
    echo "'$script_dir/env.profile' not load"
    exit 1
fi

cat <<"EOF" | tee ~/copy_cert.sh
#!/bin/sh

set -x

CONTROL_PLANE_IPS="k8s2 k8s3"
# 这里root是必须的, 因为kubernetes是特权进程, 另外如果不是root scp 写目标时会提示没权限
USER=root
pki_dir=/etc/kubernetes/pki
for host in ${CONTROL_PLANE_IPS}; do
  ssh "${USER}"@$host "rm -rf ~${pki_dir}"
  ssh "${USER}"@$host "mkdir -p ~${pki_dir}/etcd"
  scp ${pki_dir}/ca.crt "${USER}"@$host:${pki_dir}/ca.crt
  scp ${pki_dir}/ca.key "${USER}"@$host:${pki_dir}/ca.key
  scp ${pki_dir}/sa.key "${USER}"@$host:${pki_dir}/sa.key
  scp ${pki_dir}/sa.pub "${USER}"@$host:${pki_dir}/sa.pub
  scp ${pki_dir}/front-proxy-ca.crt "${USER}"@$host:${pki_dir}/front-proxy-ca.crt
  scp ${pki_dir}/front-proxy-ca.key "${USER}"@$host:${pki_dir}/front-proxy-ca.key
  scp ${pki_dir}/etcd/ca.crt "${USER}"@$host:~${pki_dir}/etcd/ca.crt
  # 如果你正使用外部 etcd, 忽略下一行
  scp ${pki_dir}/etcd/ca.key "${USER}"@$host:~${pki_dir}/etcd/ca.key
done
EOF

chmod +x ~/copy_cert.sh

# 这里使用ip地址, 如果使用域名则需要配置主机的host, 或者通过其他域名解析方案
kubeadm init --control-plane-endpoint ${LOADBALANCE_VIP}:${APISERVER_DEST_PORT} --apiserver-advertise-address ${NODE_IP}
# 上述命令会答应token 保留备用

~/copy_cert.sh