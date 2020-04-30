#!/bin/bash

for i in {1..20}
do
   frontend=flask-$i
   echo $frontend
   kubectl delete ns $frontend
done
