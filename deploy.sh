#!/bin/bash

for i in {1..2}
do
    frontend=nginx-$i
    backend=flask-$i
    svcfrontend=svc-nginx-$i
    svcbackend=svc-flask-$i
    ingressNginx=nginx-ingress-flask-$i
    echo $frontend
    echo $backend
    echo $svcfrontend
    echo $svcbackend
    echo $ingressNginx

    kubectl create ns $frontend

    cat <<EOF | kubectl apply -f -
    apiVersion: "apps/v1"
    kind: "Deployment"
    metadata:
      name: $frontend
      namespace: $frontend
      labels:
        app: $frontend
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: $frontend
      template:
        metadata:
          labels:
            app: $frontend
        spec:
          affinity:
            nodeAffinity:
              requiredDuringSchedulingIgnoredDuringExecution:
                nodeSelectorTerms:
                - matchExpressions:
                  - key: kubernetes.io/hostname
                    operator: In
                    values:
                    - mtn52r08c001
          containers:
          - name: $frontend
            image: docker.io/library/nginx-flask:latest
            ports:
            - containerPort: 80
            imagePullPolicy: IfNotPresent
EOF


    cat <<EOF | kubectl apply -f -
    apiVersion: "v1"
    kind: "Service"
    metadata:
      name: $svcfrontend
      namespace: $frontend
    spec:
      ports:
      - protocol: "TCP"
        port: 80
      selector:
        app: $frontend

EOF

    cat <<EOF | kubectl apply -f -
    apiVersion: "apps/v1"
    kind: "Deployment"
    metadata:
      name: $backend
      namespace: $frontend
      labels:
        app: $backend
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: $backend
      template:
        metadata:
          labels:
            app: $backend
        spec:
          affinity:
            nodeAffinity:
              requiredDuringSchedulingIgnoredDuringExecution:
                nodeSelectorTerms:
                - matchExpressions:
                  - key: kubernetes.io/hostname
                    operator: In
                    values:
                    - mtn52r08c001
          containers:
          - name: $backend
            image: "docker.io/library/docker_flask:latest"
            imagePullPolicy: IfNotPresent
            ports:
            - containerPort: 5000

EOF

    cat <<EOF | kubectl apply -f -
    apiVersion: v1
    kind: Service
    metadata:
      name: $svcbackend
      namespace: $frontend
    spec:
      ports:
      - nodePort: $port
        port: 5000
        protocol: TCP
        targetPort: 5000
      selector:
        app: $backend
      type: NodePort

EOF

#    cat <<EOF | kubectl apply -f -
#    apiVersion: extensions/v1beta1
#    kind: Ingress
#    metadata:
#      annotations:
#        nginx.ingress.kubernetes.io/rewrite-target: /
#      name: $ingressNginx
#      namespace: $frontend
#    spec:
#      rules:
#      - http:
#          paths:
#          - backend:
#              serviceName: $svcfrontend
#              servicePort: 80
#            path: /$ingressNginx
#
#EOF
##    cat <<EOF | kubectl apply -f -
##    apiVersion: networking.k8s.io/v1
##    kind: NetworkPolicy
##    metadata:
##      namespace: $frontend
##      name: ingress-egress-deny-$frontend
##    spec:
##      podSelector: {}
##      policyTypes:
##      - Ingress
##      - Egress
##EOF
#
#    cat <<EOF | kubectl apply -f -
#    apiVersion: networking.k8s.io/v1
#    kind: NetworkPolicy
#    metadata:
#      name: ingress-network-policy-$frontend
#      namespace: $frontend
#    spec:
#      podSelector:
#        matchLabels:
#          app: $backend
#      policyTypes:
#      - Ingress
#      ingress:
#      - from:
#        - podSelector:
#            matchLabels:
#               app: $frontend
#EOF
#
##    cat <<EOF | kubectl apply -f -
##    apiVersion: networking.k8s.io/v1
##    kind: NetworkPolicy
##    metadata:
##      name: egress-network-policy-$frontend
##      namespace: $frontend
##    spec:
##      podSelector:
##        matchLabels:
##          app: $frontend
##      policyTypes:
##      - Egress
##      egress:
##      - to:
##        - podSelector:
##            matchLabels:
##              app: $backend
##EOF
#    cat <<EOF | kubectl apply -f -
#    kind: NetworkPolicy
#    apiVersion: networking.k8s.io/v1
#    metadata:
#      name: api-allow-$frontend
#      namespace: $frontend
#    spec:
#      podSelector:
#        matchLabels:
#          app: $frontend
#      ingress:
#        - from:
#          - namespaceSelector:     # chooses all pods in namespaces labelled with team=operations
#              matchLabels:
#                app.kubernetes.io/name: ingress-nginx
#EOF
#
#      echo /$ingressNginx >> paths.txt

done
