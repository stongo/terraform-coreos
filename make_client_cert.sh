#!/bin/bash
set -e

mkdir -p client
terraform output ca_key > client/ca.key
terraform output ca_cert > client/ca.pem
openssl req -new -nodes -keyout client/client.key -out client/client.csr -subj "/C=US/ST=WA/L=Richland/O=andyet/CN=etcd-client"
openssl x509 -req -days 365 -in client/client.csr -CA client/ca.pem -CAkey client/ca.key -out client/client.pem -set_serial $RANDOM
rm client/ca.key client/client.csr
