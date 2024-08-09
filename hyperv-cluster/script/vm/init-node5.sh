sudo tee -a /etc/profile <<-EOF
export NODE_IP=192.168.98.205
export NODE_NAME=k8s5
EOF
source /etc/profile

echo ${NODE_NAME} | sudo tee /etc/hostname
sudo hostname -F /etc/hostname

sudo sed "s/192.168.98.200\/24/${NODE_IP}\/24/g" /etc/netplan/50-cloud-init.yaml -i
sudo netplan apply 