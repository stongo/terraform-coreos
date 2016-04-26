#cloud-config

coreos:
  etcd2:
    name: ${name}
    discovery-srv: ${domain}
    initial-cluster-state: new
    initial-advertise-peer-urls: http://$private_ipv4:2380
    advertise-client-urls: http://${name}.${domain}:2379
    listen-client-urls: http://127.0.0.1:2379,http://${name}.${domain}:2379
    listen-peer-urls: http://$private_ipv4:2380
  update:
    reboot-strategy: ${reboot_strategy}
  units:
    - name: etcd2.service
      command: start
