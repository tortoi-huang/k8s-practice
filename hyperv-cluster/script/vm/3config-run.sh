#!/bin/bash

# 遇到错误时停止执行后续语句
set -e

set -x
script_dir="$(dirname "$0")"
source $script_dir/env.profile
if [ ! -n "$LOADBALANCE_VIP" ]; then 
    echo "'$script_dir/env.profile' not load"
    exit 1
fi

sudo mkdir -p /etc/containerd/certs.d/_default /etc/containerd/certs.d/docker.io /etc/containerd/certs.d/registry.k8s.io

# journalctl -fu containerd
# containerd 配置文件
sudo tee /etc/containerd/config.toml <<-"EOF"
version = 2
# [cgroup]
#   driver = "systemd"
[plugins]
  [plugins."io.containerd.grpc.v1.cri"]
    # systemd_cgroup = true
    [plugins."io.containerd.grpc.v1.cri".containerd]
      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
            SystemdCgroup = true

    [plugins."io.containerd.grpc.v1.cri".registry]
      config_path = "/etc/containerd/certs.d"
EOF

# 默认仓库配置
sudo tee /etc/containerd/certs.d/_default/hosts.toml <<-EOF
[host."${MIRROR_DOCKER}"]
  capabilities = ["pull", "resolve"]
EOF

# docker 仓库配置
sudo tee /etc/containerd/certs.d/docker.io/hosts.toml <<-EOF
server = "https://docker.io"

[host."${MIRROR_DOCKER}"]
  capabilities = ["pull", "resolve"]
EOF

# k8s 仓库配置
sudo tee /etc/containerd/certs.d/registry.k8s.io/hosts.toml <<-EOF
server = "https://registry.k8s.io"

[host."${MIRROR_K8S}"]
  capabilities = ["pull", "resolve"]
EOF