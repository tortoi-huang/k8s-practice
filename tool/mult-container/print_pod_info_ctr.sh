##!/usr/bin/env sh
echo > info.txt
microk8s ctr c ls|grep nginx:1.24.0|awk '{print "microk8s ctr c info " $1 " >> info.txt"}'|sh