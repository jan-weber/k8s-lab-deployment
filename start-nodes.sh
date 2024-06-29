#!/bin/zsh

multipass start k8s-master
multipass start k8s-worker1
multipass start k8s-worker2
multipass start k8s-worker3
multipass start k8s-worker4
multipass list