provider "digitalocean" {
  token = "${var.do_token}"
}

provider "dnsimple" {
  email = "${var.dnsimple_email}"
  token = "${var.dnsimple_token}"
}

resource "tls_private_key" "ca" {
  algorithm = "ECDSA"
  ecdsa_curve = "P384"
  provisioner "local-exec" {
    command = "echo \"${tls_private_key.ca.private_key_pem}\" > ca.key"
  }
}

resource "tls_self_signed_cert" "ca" {
  key_algorithm = "${tls_private_key.ca.algorithm}"
  private_key_pem = "${tls_private_key.ca.private_key_pem}"
  validity_period_hours = 43800
  is_ca_certificate = "true"
  allowed_uses = ["cert_signing", "key_encipherment", "client_auth", "server_auth"]
  subject = {
    common_name = "${var.cluster_name}.${var.dnsimple_domain}"
    organization = "&yet, LLC"
  }

  provisioner "local-exec" {
    command = "echo \"${tls_self_signed_cert.ca.cert_pem}\" > ca.pem"
  }
}

resource "tls_private_key" "server" {
  count = "${var.instance_count}"
  algorithm = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_cert_request" "server" {
  count = "${var.instance_count}"
  key_algorithm = "${element(tls_private_key.server.*.algorithm, count.index)}"
  private_key_pem = "${element(tls_private_key.server.*.private_key_pem, count.index)}"
  dns_names = ["${format("${var.cluster_name}-%02d.${var.dnsimple_domain}", count.index)}"]
  subject = {
    common_name = "${var.cluster_name}.${var.dnsimple_domain}"
    organization = "&yet, LLC"
  }
}

resource "tls_locally_signed_cert" "server" {
  count = "${var.instance_count}"
  cert_request_pem = "${element(tls_cert_request.server.*.cert_request_pem, count.index)}"
  ca_key_algorithm = "${tls_private_key.ca.algorithm}"
  ca_private_key_pem = "${tls_private_key.ca.private_key_pem}"
  ca_cert_pem = "${tls_self_signed_cert.ca.cert_pem}"
  allowed_uses = ["key_encipherment", "server_auth"]
  validity_period_hours = 43800
}

resource "tls_locally_signed_cert" "client" {
  count = "${var.instance_count}"
  cert_request_pem = "${element(tls_cert_request.server.*.cert_request_pem, count.index)}"
  ca_key_algorithm = "${tls_private_key.ca.algorithm}"
  ca_private_key_pem = "${tls_private_key.ca.private_key_pem}"
  ca_cert_pem = "${tls_self_signed_cert.ca.cert_pem}"
  allowed_uses = ["key_encipherment", "client_auth"]
  validity_period_hours = 43800
}

resource "template_file" "member" {
  count = "${var.instance_count}"
  template = "${file("cloud-config.tpl")}"
  vars {
    domain = "${var.dnsimple_domain}"
    name = "${format("${var.cluster_name}-%02d", count.index)}"
    ca = "${base64encode(tls_self_signed_cert.ca.cert_pem)}"
    key = "${base64encode(element(tls_private_key.server.*.private_key_pem, count.index))}"
    cert = "${base64encode(element(tls_locally_signed_cert.server.*.cert_pem, count.index))}"
    client = "${base64encode(element(tls_locally_signed_cert.client.*.cert_pem, count.index))}"
  }
}

resource "digitalocean_droplet" "member" {
  count = "${var.instance_count}"
  name = "${format("${var.cluster_name}-%02d", count.index)}"
  image = "coreos-${var.coreos_channel}"
  region = "${var.instance_region}"
  size = "${var.instance_size}"
  ssh_keys = ["${var.ssh_fingerprint}"]
  user_data = "${element(template_file.member.*.rendered, count.index)}"
  private_networking = "true"
}

resource "dnsimple_record" "hostnames" {
  count = "${var.instance_count}"
  domain = "${var.dnsimple_domain}"
  name = "${format("${var.cluster_name}-%02d", count.index)}"
  value = "${element(digitalocean_droplet.member.*.ipv4_address, count.index)}"
  type = "A"
  ttl = 60
}

resource "dnsimple_record" "etcd_server_discovery" {
  count = "${var.instance_count}"
  domain = "${var.dnsimple_domain}"
  name = "_etcd-server._tcp"
  value = "0 2380 ${element(digitalocean_droplet.member.*.ipv4_address_private, count.index)}"
  type = "SRV"
  ttl = 60
}

resource "dnsimple_record" "etcd_client_discovery" {
  count = "${var.instance_count}"
  domain = "${var.dnsimple_domain}"
  name = "_etcd-client._tcp"
  value = "0 2379 ${element(digitalocean_droplet.member.*.ipv4_address_private, count.index)}"
  type = "SRV"
  ttl = 60
}

resource "dnsimple_record" "etcd_client_ssl_discovery" {
  count = "${var.instance_count}"
  domain = "${var.dnsimple_domain}"
  name = "_etcd-client-ssl._tcp"
  value = "0 2379 ${format("${var.cluster_name}-%02d.${var.dnsimple_domain}", count.index)}"
  type = "SRV"
  ttl = 60
}
