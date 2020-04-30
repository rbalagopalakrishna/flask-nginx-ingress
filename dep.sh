#!/bin/bash

for i in {20..40}
do
    frontend=nginx-$i
    backend=flask-$i
    svcfrontend=svc-nginx-$i
    svcbackend=svc-flask-$i
    ingressNginx=home-$i
    echo $frontend
    echo $backend
    echo $svcfrontend
    echo $svcbackend
    echo $ingressNginx

    port=$(shuf -i 30400-30500 -n1)

    kubectl create ns $frontend

    cat <<EOF | kubectl apply -f -
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: nginx-configmap-$frontend
      namespace: $frontend
    data:
      default.conf: |
        upstream $svcbackend {
            server 32.68.220.18;
        }

        server {
            listen 80;
        
            location / {
                    proxy_pass http://32.68.220.18:$port;
            }
        }

EOF

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
            volumeMounts:
            - name: config-volume
              mountPath: /etc/nginx/conf.d/
          volumes:
          - name: config-volume
            configMap:
              name: nginx-configmap-$frontend
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
                    - mtn52r08c002
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

    cat <<EOF | kubectl apply -f -
    apiVersion: extensions/v1beta1
    kind: Ingress
    metadata:
      annotations:
        kubernetes.io/ingress.class: nginx-cluster
        nginx.ingress.kubernetes.io/ssl-redirect: "false"
        nginx.ingress.kubernetes.io/rewrite-target: /
      name: $ingressNginx
      namespace: $frontend
    spec:
      rules:
      - http:
          paths:
          - backend:
              serviceName: $svcfrontend
              servicePort: 80
            path: /$ingressNginx

EOF
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
    cat <<EOF | kubectl apply -f -
    kind: NetworkPolicy
    apiVersion: networking.k8s.io/v1
    metadata:
      name: api-allow-$frontend
      namespace: $frontend
    spec:
      podSelector:
        matchLabels:
          app: $frontend
      policyTypes:
      - Ingress
      ingress:
        - from:
          - ipBlock:
              cidr: 172.29.1.0/25
EOF

      echo /$ingressNginx >> paths.txt

done
