#cloud-config

coreos:
  etcd2:
    name: ${name}
    discovery-srv: ${domain}
    initial-cluster-state: new
    initial-advertise-peer-urls: http://$private_ipv4:2380
    advertise-client-urls: https://${name}.${domain}:2379
    listen-client-urls: http://127.0.0.1:2379,https://${name}.${domain}:2379
    listen-peer-urls: http://$private_ipv4:2380
    client-cert-auth: true
    trusted-ca-file: /etc/ssl/etcd/ca.pem
    cert-file: /etc/ssl/etcd/cert.pem
    key-file: /etc/ssl/etcd/key.pem
  update:
    reboot-strategy: etcd-lock
  units:
    - name: etcd2.service
      command: start
    - name: vault.service
      command: start
      content: |
        [Unit]
        Description="Vault server"
        [Service]
        ExecStartPre=/bin/bash -c '[ ! -f /srv/vault ] && (cd /tmp; curl -qO ${vault_url}; unzip -d /srv vault*.zip) || true'
        ExecStart=/srv/vault server -config /etc/vault.hcl
        Restart=always
write_files:
  - path: /etc/ssl/etcd/ca.pem
    permissions: 0644
    owner: root
    encoding: base64
    content: ${ca}
  - path: /etc/ssl/etcd/key.pem
    permissions: 0644
    owner: root
    encoding: base64
    content: ${key}
  - path: /etc/ssl/etcd/cert.pem
    permissions: 0644
    owner: root
    encoding: base64
    content: ${cert}
  - path: /etc/ssl/etcd/client.pem
    permissions: 0644
    owner: root
    encoding: base64
    content: ${client}
  - path: /etc/profile.d/etcdctl_env.sh
    permissions: 0755
    owner: root
    content: |
      export ETCDCTL_CERT_FILE=/etc/ssl/etcd/client.pem
      export ETCDCTL_KEY_FILE=/etc/ssl/etcd/key.pem
      export ETCDCTL_CA_FILE=/etc/ssl/etcd/ca.pem
  - path: /etc/ssl/${domain}.pem
    permissions: 0644
    owner: root
    encoding: base64
    content: ${domain_cert}
  - path: /etc/ssl/${domain}.key
    permissions: 0644
    owner: root
    encoding: base64
    content: ${domain_key}
  - path: /etc/vault.hcl
    permissions: 0644
    owner: root
    content: |
      backend "etcd" {
        address = "http://127.0.0.1:2379"
        advertise_addr = "https://${name}.${domain}:8200"
        tls_ca_file = "/etc/ssl/etcd/ca.pem"
        tls_key_file = "/etc/ssl/etcd/key.pem"
        tls_cert_file = "/etc/ssl/etcd/client.pem"
      }

      listener "tcp" {
        address = "0.0.0.0:8200"
        tls_cert_file = "/etc/ssl/${domain}.pem"
        tls_key_file = "/etc/ssl/${domain}.key"
      }
