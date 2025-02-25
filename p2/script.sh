#!/bin/bash

sudo apt update -y && sudo apt upgrade -y 
command -v curl
if [ $? -gt 0 ]; then
  sudo apt install curl -y 
fi


command -v k3s
if [ $? -gt 0 ]; then
  curl -sfL https://get.k3s.io | sh -s - --flannel-iface eth1
fi

echo " ******** DEPLOYMENT ********"
cd deployment 
kubectl apply -f .

sleep 10s ;  kubectl wait --for=condition=Ready pods --all --timeout=300s 


echo " ******** SERVICES ********"

cd ../services 
kubectl apply -f . 

kubectl wait --for=jsonpath='{.spec.selector.app}' -f ./ --timeout=300s 


echo " ******** INGRESS ********"
cd ../ingress 
 kubectl apply -f . 




echo " ******** END ********"