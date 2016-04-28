#!/bin/bash
cd /etc/kubernetes/ssl
sudo openssl req -new -key apiserver-key.pem -out apiserver.csr -subj "/CN=kube-apiserver" -config openssl.cnf
sudo openssl x509 -req -in apiserver.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out apiserver.pem -days 365 -extensions v3_req -extfile openssl.cnf
sudo rm apiserver.csr ca-key.pem
sudo chmod 600 *-key.pem
sudo chown root:root *-key.pem
