#!/bin/bash

for i in {21..21}
do
    frontend=flask-$i
    backend=postgres-$i
    svcfrontend=svc-flask-$i
    svcbackend=svc-postgres-$i
    ingressNginx=nginx-ingress-flask-$i
    dburl=postgres://mudasir:12345@$svcbackend:5432/demo_db
    echo $frontend
    echo $backend
    echo $svcfrontend
    echo $svcbackend
    echo $dburl
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
            image: "flask-image:latest"
            imagePullPolicy: IfNotPresent
            env:
            - name: DATABASE_URL
              value: $dburl
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
        targetPort: 5000
      selector:
        app: $frontend
EOF
    cat <<EOF | kubectl apply -f -
    apiVersion: "v1"
    kind: "ConfigMap"
    metadata:
      name: "postgres-config"
      namespace: $frontend
      labels:
        app: "postgres"
    data:
      POSTGRES_DB: "demo_db"
      POSTGRES_USER: "mudasir"
      POSTGRES_PASSWORD: "12345"
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
            image: "postgres:9.6.2"
            imagePullPolicy: IfNotPresent
            env:
            - name: "POSTGRES_DB"
              valueFrom:
                configMapKeyRef:
                  key: "POSTGRES_DB"
                  name: "postgres-config"
            - name: "POSTGRES_USER"
              valueFrom:
                configMapKeyRef:
                  key: "POSTGRES_USER"
                  name: "postgres-config"
            - name: "POSTGRES_PASSWORD"
              valueFrom:
                configMapKeyRef:
                  key: "POSTGRES_PASSWORD"
                  name: "postgres-config"
            ports:
              - containerPort: 5432
                name: $backend
            volumeMounts:
              - name: postgres-storage
                mountPath: /var/lib/postgresql/db-data
          volumes:
            - name: postgres-storage
              emptyDir: {}
EOF

    cat <<EOF | kubectl apply -f -
    apiVersion: v1
    kind: Service
    metadata:
      name: $svcbackend
      namespace: $frontend
    spec:
      ports:
        - port: 5432
      selector:
        app: $backend


EOF

    cat <<EOF | kubectl apply -f -
    apiVersion: extensions/v1beta1
    kind: Ingress
    metadata:
      annotations:
        kubernetes.io/ingress.class: nginx-cluster
        nginx.ingress.kubernetes.io/rewrite-target: /
        nginx.ingress.kubernetes.io/ssl-redirect: "false"
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
#    cat <<EOF | kubectl apply -f -
#    apiVersion: networking.k8s.io/v1
#    kind: NetworkPolicy
#    metadata:
#      namespace: $frontend
#      name: ingress-egress-deny-$frontend
#    spec:
#      podSelector: {}
#      policyTypes:
#      - Ingress
#      - Egress
#EOF

    cat <<EOF | kubectl apply -f -
    apiVersion: networking.k8s.io/v1
    kind: NetworkPolicy
    metadata:
      name: ingress-network-policy-$frontend
      namespace: $frontend
    spec:
      podSelector:
        matchLabels:
          app: $backend
      policyTypes:
      - Ingress
      ingress:
      - from:
        - podSelector:
            matchLabels:
               app: $frontend
EOF

#    cat <<EOF | kubectl apply -f -
#    apiVersion: networking.k8s.io/v1
#    kind: NetworkPolicy
#    metadata:
#      name: egress-network-policy-$frontend
#      namespace: $frontend
#    spec:
#      podSelector:
#        matchLabels:
#          app: $frontend
#      policyTypes:
#      - Egress
#      egress:
#      - to:
#        - podSelector:
#            matchLabels:
#              app: $backend
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
      ingress:
        - from:
          - namespaceSelector:     # chooses all pods in namespaces labelled with team=operations
              matchLabels:
                app.kubernetes.io/name: ingress-nginx
EOF
      echo /$ingressNginx >> paths.txt

done
