#!/bin/zsh

#install on mac in zsh
brew install multipass
multipass launch -n k8s-master -c 2 -m 4G -d 20G
multipass launch -n k8s-worker1 -c 2 -m 4G -d 20G
multipass launch -n k8s-worker2 -c 2 -m 4G -d 20G
multipass launch -n k8s-worker3 -c 1 -m 4G -d 20G
multipass launch -n k8s-worker4 -c 1 -m 4G -d 20G
multipass list