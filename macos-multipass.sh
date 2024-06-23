#!/bin/zsh

#install on mac in zsh
brew install multipass
multipass launch --name k8s-master --cpus 2 --mem 4G --disk 20G
multipass launch --name k8s-worker1 --cpus 2 --mem 4G --disk 20G
multipass launch --name k8s-worker2 --cpus 2 --mem 4G --disk 20G
multipass list