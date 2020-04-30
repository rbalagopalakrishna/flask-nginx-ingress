#!/bin/bash

for j in {1..20}
do
  for i in {8000..8050}
  do
      frontend=postgres-$j
      echo $frontend
  
      cat <<EOF | kubectl apply -f -
      apiVersion: networking.k8s.io/v1
      kind: NetworkPolicy
      metadata:
        namespace: postgres-$j
        name: access-nginx-postgres-$i
      spec:
        podSelector:
          matchLabels:
            app: postgres-$j
        ingress:
        - from:
          - podSelector:
              matchLabels:
                app: postgres-$j
          ports:
          - protocol: TCP
            port: $i
EOF
done
done
#for i in {9025..9035}
#do
#    frontend=flask-$i
#    echo $frontend
#
#
#    cat <<EOF | kubectl apply -f -
#    apiVersion: networking.k8s.io/v1
#    kind: NetworkPolicy
#    metadata:
#      name: ingress-network-policy-$frontend
#      namespace: flask-1
#    spec:
#      podSelector:
#        matchLabels:
#          app: flask-1
#      policyTypes:
#      - Ingress
#      ingress:
#      - from:
#        - podSelector:
#            matchLabels:
#               app: flask-1
#EOF
#done
