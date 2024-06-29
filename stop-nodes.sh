#!/bin/zsh

multipass stop k8s-master
multipass stop k8s-worker1
multipass stop k8s-worker2
multipass stop k8s-worker3
multipass stop k8s-worker4
multipass list