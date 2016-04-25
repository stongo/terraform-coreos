#cloud-config
coreos:
    update:
        reboot-strategy: off
    etcd2:
        discovery-srv: ${domain}
        proxy: on
    flannel:
        interface: $public_ipv4
        etcd_endpoints: ${etcd_endpoints}
    units:
        - name: flanneld.service
          command: start
          after: etcd2
          drop-ins:
            - name: "40-packet-dependency.conf"
              content: |
                [Unit]
                After=oem-phone-home.service
                Requires=oem-phone-home.service
                [Service]
                ExecStartPre=/usr/bin/etcdctl -D ${domain} --no-sync set /coreos.com/network/config '{"Network":"172.16.0.0/16","Backend":{"Type":"vxlan"}}'
        - name: docker.service
          drop-ins:
            - name: "40-flannel.conf"
              content: |
                [Unit]
                After=oem-phone-home.service
                Requires=oem-phone-home.service
                Requires=flanneld.service
                After=flanneld.service
        - name: kube-apiserver.service
          command: start
          content: |
            [Unit]
            Description="Kubernetes API Server"
            After=oem-phone-home.service
            Requires=oem-phone-home.service
            Requires=kubernetes-certs.service
            After=kubernetes-certs.service
            [Service]
            TimeoutStartSec=300
            ExecStartPre=/bin/docker pull quay.io/coreos/hyperkube:v1.2.0_coreos.0
            ExecStart=/bin/docker run --rm --name kube-apiserver --net host \
              -v /etc/kubernetes/ssl:/etc/kubernetes/ssl:ro -v /usr/share/ca-certificates:/etc/ssl/certs:ro \
              quay.io/coreos/hyperkube:v1.2.0_coreos.0 \
                /hyperkube \
                apiserver \
                --bind-address=0.0.0.0 \
                --etcd-servers=${etcd_endpoints} \
                --allow-privileged=true \
                --portal_net=172.16.0.0/24 \
                --secure-port=443 \
                --advertise-address=$public_ipv4 \
                --admission-control=NamespaceLifecycle,NamespaceExists,LimitRanger,SecurityContextDeny,ServiceAccount,ResourceQuota \
                --tls-cert-file=/etc/kubernetes/ssl/apiserver.pem \
                --tls-private-key-file=/etc/kubernetes/ssl/apiserver-key.pem \
                --client-ca-file=/etc/kubernetes/ssl/ca.pem \
                --kubelet-certificate-authority=/etc/kubernetes/ssl/ca.pem \
                --service-account-key-file=/etc/kubernetes/ssl/apiserver-key.pem \
                --service-cluster-ip-range=172.17.0.0/16
            ExecStop=/bin/docker stop -t 2 kube-apiserver
        - name: kube-proxy.service
          command: start
          content: |
            [Unit]
            Description="Kubernetes Proxy"
            Requires=kube-apiserver.service
            After=oem-phone-home.service
            Requires=oem-phone-home.service
            After=kube-apiserver.service
            [Service]
            TimeoutStartSec=300
            ExecStartPre=/bin/docker pull quay.io/coreos/hyperkube:v1.2.0_coreos.0
            ExecStart=/bin/docker run --rm --name kube-proxy --privileged --net host \
              -v /usr/share/ca-certificates:/etc/ssl/certs:ro \
              quay.io/coreos/hyperkube:v1.2.0_coreos.0 \
              /hyperkube \
              proxy \
              --master=127.0.0.1:8080 \
              --proxy-mode=iptables
            ExecStop=/bin/docker stop -t 2 kube-proxy
        - name: kube-controller-manager.service
          command: start
          content: |
            [Unit]
            Description="Kubernetes Controller Manager"
            After=oem-phone-home.service
            Requires=oem-phone-home.service
            Requires=kube-apiserver.service
            After=kube-apiserver.service
            [Service]
            TimeoutStartSec=300
            ExecStartPre=/bin/docker pull quay.io/coreos/hyperkube:v1.2.0_coreos.0
            ExecStart=/bin/docker run --rm --name kube-controller-manager --net host \
              -v /etc/kubernetes/ssl:/etc/kubernetes/ssl:ro -v /etc/ssl/certs:/usr/share/ca-certificates:ro \
              quay.io/coreos/hyperkube:v1.2.0_coreos.0 \
              /hyperkube \
              controller-manager \
              --master=127.0.0.1:8080 \
              --service-account-private-key-file=/etc/kubernetes/ssl/apiserver-key.pem \
              --root-ca-file=/etc/kubernetes/ssl/ca.pem
            ExecStop=/bin/docker stop -t 2 kube-controller-manager
        - name: kube-scheduler.service
          command: start
          content: |
            [Unit]
            Description="Kubernetes Scheduler"
            Requires=kube-apiserver.service
            After=oem-phone-home.service
            Requires=oem-phone-home.service
            After=kube-apiserver.service
            [Service]
            TimeoutStartSec=300
            ExecStartPre=/bin/docker pull quay.io/coreos/hyperkube:v1.2.0_coreos.0
            ExecStart=/bin/docker run --rm --name kube-scheduler --net host \
              quay.io/coreos/hyperkube:v1.2.0_coreos.0 \
              /hyperkube \
              scheduler \
              --master=127.0.0.1:8080
            ExecStop=/bin/docker stop -t 2 kube-scheduler
        - name: kubernetes-certs.service
          command: start
          content: |
            [Unit]
            Description="creates required kubernetes master certs"
            After=oem-phone-home.service
            Requires=oem-phone-home.service
            [Service]
            ExecStart=/etc/kubernetes/ssl/create_certs.sh
            RemainAfterExit=yes
            Type=oneshot
        - name: sshd.socket
          command: restart
          content: |
            [Socket]
            ListenStream=2042
            Accept=yes
        - name: settimezone.service
          command: start
          content: |
            [Unit]
            Description=Set the timezone
            After=oem-phone-home.service
            Requires=oem-phone-home.service

            [Service]
            ExecStart=/usr/bin/timedatectl set-timezone UTC
            RemainAfterExit=yes
            Type=oneshot
write_files:
  - path: /etc/ntp.conf
    content: |
      # Common pool
      server 0.pool.ntp.org
      server 1.pool.ntp.org

      # - Allow only time queries, at a limited rate.
      # - Allow all local queries (IPv4, IPv6)
      restrict default nomodify nopeer noquery limited kod
      restrict 127.0.0.1
      restrict [::1]
  - path: /etc/ssh/sshd_config
    permissions: 0600
    owner: root:root
    content: |
      # Use most defaults for sshd configuration.
      UsePrivilegeSeparation sandbox
      Subsystem sftp internal-sftp

      PermitRootLogin no
      AllowUsers core
      PasswordAuthentication no
      ChallengeResponseAuthentication no
  - path: /etc/kubernetes/ssl/ca.pem
    permissions: 644
    content: |
      -----BEGIN CERTIFICATE-----
      MIIDGjCCAgKgAwIBAgIJALxqgldpO58gMA0GCSqGSIb3DQEBBQUAMBIxEDAOBgNV
      BAMTB2t1YmUtY2EwHhcNMTYwMzIyMTMyMTQ1WhcNNDMwODA4MTMyMTQ1WjASMRAw
      DgYDVQQDEwdrdWJlLWNhMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA
      qbNYQq6vcKp2ugtfHI7+Z+lcqNyM++X6kCWAkrKvyJ9b+ZPYBj1NuWZiLl5FS3kl
      AFPRjtwWaL+FJmRCvFIDRTruSjM1AraoQt+a8tA/zO+bRmWW++xfB9VMDqHob+AP
      zNA747GU3F80uEDXtXZK/SdZHDKi4vj0oNnkVmC1UcmWHdng3LydDF2DTz4bZSzo
      uDr1MCMRKFW+bUGF7aii3q27xwCs3of2bsaieU1lmsQE3RBUXnwlqjvbjoaxVOT7
      2pnoos2EVViMQsCAtHIpdfV1DSm+QvrMc6dMogy1Ff5iSYNKjHKPVopkATpUQsOt
      /Xql/GlOIkCyr8W0CI4CdwIDAQABo3MwcTAdBgNVHQ4EFgQUEzjp6GcXgIqgt5eE
      iGO65GwqP4kwQgYDVR0jBDswOYAUEzjp6GcXgIqgt5eEiGO65GwqP4mhFqQUMBIx
      EDAOBgNVBAMTB2t1YmUtY2GCCQC8aoJXaTufIDAMBgNVHRMEBTADAQH/MA0GCSqG
      SIb3DQEBBQUAA4IBAQA5H9wA/YS3vKUEX93w+CpAbpLebFo7PCmX5TZ1x7K7GCN4
      StUG+68XvvYwfSRp7x2iiTdvg9FJiJgFqUA0XR2tFJcT+D8KwFxgayVWnsY7bMQ6
      QC1yGce3FuW0mhGqQQ4xrD0PobvUmOjb+TGTHHqROqkTde2MYSMhZbnwh67MQ1iA
      nQ7sBqI9mrgrgXia+dQfRbc1rJaHm6fwsoR9cq+5uY4eq/0soqz1I8N1f4pKs0F4
      ufj9vR6zgifG3JK3ldV/b1Rhw/ojbZ+lsHnTIxFD3IXVe4Ueji3aKQTVrVWX3FmW
      2gxIiHJ5woOMjRBaVbUzIpjodmfK5wWRFOJpt62T
      -----END CERTIFICATE-----
  - path: /etc/kubernetes/ssl/ca-key.pem
    permissions: 644
    content: |
      -----BEGIN RSA PRIVATE KEY-----
      MIIEpAIBAAKCAQEAqbNYQq6vcKp2ugtfHI7+Z+lcqNyM++X6kCWAkrKvyJ9b+ZPY
      Bj1NuWZiLl5FS3klAFPRjtwWaL+FJmRCvFIDRTruSjM1AraoQt+a8tA/zO+bRmWW
      ++xfB9VMDqHob+APzNA747GU3F80uEDXtXZK/SdZHDKi4vj0oNnkVmC1UcmWHdng
      3LydDF2DTz4bZSzouDr1MCMRKFW+bUGF7aii3q27xwCs3of2bsaieU1lmsQE3RBU
      XnwlqjvbjoaxVOT72pnoos2EVViMQsCAtHIpdfV1DSm+QvrMc6dMogy1Ff5iSYNK
      jHKPVopkATpUQsOt/Xql/GlOIkCyr8W0CI4CdwIDAQABAoIBAQCBLTrvL4furGPK
      BOP2mkbAFJxrEc/j49FSrqlrgcdbYSsjFU5omXuzuGLeRvZamDH5SNSI+bG5NKiH
      a+R887T3mv9OziH5Gc+FcC7DzI/0USQSdzxyMiC4lr3ZmZeUqat9Tbl4/nGBOpun
      8fwBbrVwdOZZF5Z0TevxEUvGEMGVKi+Shwp4W52wNs1B4RVRjm7PRX0AV1YKDZZ5
      p+YwOstfONrCmi3fEyMxQ+Blmrdx9K5R1BllcI8TVq+gjIRZNpSsHjqvN6k5Ki4B
      CfFLxBNgYX6OS1RwJYEYSAOJ1iVaDGX/uXSA02KAlaZ9t3zMjg+t2wi6FiITLLuC
      t1kPWwqRAoGBANm7qKZDLKpY7Ok7VCu+/wYGiqHDkyRz5Ql14BlKV3PpKnfsJbZ8
      jKtLXMpbaZD40qKJ9DmxfXpN3zVJoZ/gFeya0dZ4/CV+3lDCy1LAuDuROc0y7GOD
      izHobjMeBHg0UvNQod3mLcQyMxOYaD0hs/nzVdJdPX4N9ejkCXIhM+tJAoGBAMeG
      lms8LqMoK8EB+iVVJxBSFejaGCv1xcVLN/t9ntjZymt9MEcnHKRzo/dm0dQlkqdD
      2fTuGtBEjCHguau5R7Q59nocoLxtw+FXeD5w/ebUf1BEeX44V4Ekvpa+Lg/V2lYG
      4JJHLkjfEvC3+xWDMY9zpqXfedUxorb0mAjeFr+/AoGAB1GqkqQxbSx+Ejz/UFUk
      R3SS1ms3mAMZUN8YgGEiXXAaEFvszJyVMfDflqHKA6iJlBMlFYdk22aguS7XcwNa
      WVC++wGoIC6KlJZntUlrJ/1yvvYWQiYa2LuicK9yoQPJQgqU1lu1cCHr253E60El
      xqIqYV7nAUTA3mpD8wUwtJkCgYEAupiJj9wGmZt139jjgYpzL/Y0e0GLnYEJ5gsE
      XfQLXC3B+mhngAN56+oiC7tivI4u6rKv4TnUZbXVf9FUkt6BynDyqxyezdmxeMp+
      r5aoPPm53u1K2doDK8mbXAqbtT+AIzfnSaW8CXZlli3ZaTL6ZHf5/+JRZCo5S/TP
      QmvAxq0CgYB1s8gWxD3y253KgmDedK7hlM+0vONO4xlWBOXNPlkV3ZDg37S5QCwk
      gabKCeqValezZ2A0l1U8TQn3L/xaBjA1XidBXX/DvgQSQ9oeRez+UkCM//Vj86EU
      kes7zsew0e/FpXp4fsSpqgIHOkoTJLDJg2CcOXiL0SafFxnQBTntPQ==
      -----END RSA PRIVATE KEY-----
  - path: /etc/kubernetes/ssl/openssl.cnf
    content: |
      [req]
      req_extensions = v3_req
      distinguished_name = req_distinguished_name
      [req_distinguished_name]
      [ v3_req ]
      basicConstraints = CA:FALSE
      keyUsage = nonRepudiation, digitalSignature, keyEncipherment
      subjectAltName = @alt_names
      [alt_names]
      DNS.1 = kubernetes
      DNS.2 = kubernetes.default
      DNS.3 = kubernetes.default.svc
      DNS.4 = kubernetes.default.svc.cluster.local
      IP.1 = $public_ipv4
      IP.2 = $private_ipv4
      IP.3 = 127.0.0.1
      IP.4 = 172.17.0.1
  - path: /etc/kubernetes/ssl/create_certs.sh
    permissions: "755"
    content: |
      #!/bin/bash
      cd /etc/kubernetes/ssl
      sudo openssl genrsa -out apiserver-key.pem 2048
      sudo openssl req -new -key apiserver-key.pem -out apiserver.csr -subj "/CN=kube-apiserver" -config openssl.cnf
      sudo openssl x509 -req -in apiserver.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out apiserver.pem -days 365 -extensions v3_req -extfile openssl.cnf
      sudo rm apiserver.csr ca-key.pem
      sudo chmod 600 *-key.pem
      sudo chown root:root *-key.pem
