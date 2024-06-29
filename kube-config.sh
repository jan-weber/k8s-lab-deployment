#!/bin/bash

multipass exec k8s-master -- sudo cat /etc/kubernetes/admin.conf > kubeconfig
mkdir -p ~/.kube
cp kubeconfig ~/.kube/config
export KUBECONFIG=~/.kube/config
kubectl get nodes -A