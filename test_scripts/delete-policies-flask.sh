#!/bin/bash

kubectl get networkpolicies | grep access-nginx-flask- | cut -d " " -f1 > /tmp/ns.txt

input="/tmp/ns.txt"
while IFS= read -r line
do
  kubectl delete networkpolicies $line
done < "$input"

sudo rm /tmp/ns.txt 
