## Steps to actually provision

```
terraform apply -target=packet_device.master
terraform apply -target=dnsimple_record.master -target=dnsimple_record.server_discovery -target=dnsimple_record.client_discovery
```

at this point you'll need to physically log in to each master, make sure etcd2 syncs up (it takes a minute because of dns) and then start flanneld.service, kube-apiserver.service, kube-proxy.service, kube-scheduler.service and kube-controller-manager.service once that's all done you should be able to check logs and see things being happy, the "blah blah still has a lock" messages are normal, that's just kubernetes being chatty about its leader election. after that, bring up your workers:

```
terraform apply -target=packet_device.worker
terraform apply # this one doesn't need a specific target because everything is up by this point
```
