#!/bin/bash
cd /etc/kubernetes/ssl
openssl genrsa -out ${name}-key.pem 2048
openssl req -new -key ${name}-key.pem -out ${name}.csr -subj "/CN=${name}" -config worker-openssl.cnf
openssl x509 -req -in ${name}.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out ${name}.pem -days 365 -extensions v3_req -extfile worker-openssl.cnf
sudo chmod 600 *-key.pem
sudo chown root:root *-key.pem
echo -n "$(cat ca.pem)" | sudo tee -a ${name}.pem
