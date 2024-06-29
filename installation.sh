#!/bin/bash

###########################################
# THIS SCRIPT IS FOR LEARNING PURPOSES ONLY AND SHOULD NOT BE USED IN PRODUCTION !!!
# This script is for installing Kubernetes on Ubuntu 24.04 LTS
# Tested on multipass VM with 2 CPUs and 4GB RAM and ubuntu 24.04 LTS
# Author: Jan Weber info@janweber.cz
###########################################

# if is not ubuntu 24.04 LTS, exit
if [[ $(lsb_release -rs) != "24.04" ]]; then
  echo "This script is for Ubuntu 24.04 LTS only!"
  exit 1
fi

# Check if swap is turned on and turn it off
if swapon --summary | grep -q "file"; then
  echo "Swap is turned on. Turn off swap to continue."
  exit 1
fi

###########################################
# CONTAINER RUNTIMES SETTINGS
# Install and configure prerequisites
# https://kubernetes.io/docs/setup/production-environment/container-runtimes/
###########################################

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

# control if the sysctl param is set correctly
if [[ $(sysctl net.ipv4.ip_forward) == "net.ipv4.ip_forward = 1" ]]; then
  echo "net.ipv4.ip_forward is set to 1"
else
  echo "net.ipv4.ip_forward is not set to 1"
fi

#Install the dependencies for adding repositories
apt-get update
apt-get install -y software-properties-common curl

# Add the Kubernetes and CRI-O repositories
KUBERNETES_VERSION=v1.30
PROJECT_PATH=prerelease:/main

# Add the Kubernetes repository
curl -fsSL https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/Release.key |
    gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/ /" |
    tee /etc/apt/sources.list.d/kubernetes.list

# Add the CRI-O repository
curl -fsSL https://pkgs.k8s.io/addons:/cri-o:/$PROJECT_PATH/deb/Release.key |
    gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/$PROJECT_PATH/deb/ /" |
    tee /etc/apt/sources.list.d/cri-o.list

# Install the container runtime CRI-O, and Kubernetes packages (kubelet, kubeadm, kubectl)
apt-get update
apt-get install -y cri-o kubelet kubeadm kubectl

# Start CRI-O 
systemctl start crio.service

# Enable kubelet
systemctl enable --now kubelet

# ask user if he want set this node as first master
read -p "Do you want to set this node as first master? [y/n]: " set_master

if [[ $set_master == "y" ]]; then

  # Initialize the Kubernetes cluster
  # Set the pod network CIDR to avoid conflicts with the default network on multipass VMs (192.168.0.0/16)
  sudo kubeadm init --pod-network-cidr="10.10.0.0/16"

  # if previous command was successful, set up the kube config
  if [[ $? -eq 0 ]]; then
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
  fi
else
 # if user don't want to set this node as first master, print the command for joining the cluster
  echo "To join this node to the cluster, run the following command:"
  echo "sudo kubeadm join <control-plane-host>:<control-plane-port> --token <token> --discovery-token-ca-cert-hash sha256:<hash>"
  echo "To get the token and hash, run the following command on the master node:"
  # print the command for getting the token and hash on the master node to join new worker nodes to the cluster
  echo "kubeadm token create --print-join-command" 
fi

# Install Calico network plugin
read -p "Do you want to install Calico network plugin? [y/n]: " install_calico
if [[ $install_calico == "y" ]]; then
    kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/tigera-operator.yaml
    # Wait for the operator to be ready
    sleep 30
    # change the default IP pool CIDR to match your pod network CIDR
    kubectl create -f ./calico.yaml
fi