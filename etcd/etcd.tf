provider "digitalocean" {
  token = "${var.do_token}"
}

provider "packet" {
  token = "${var.packet_token}"
}

provider "dnsimple" {
  email = "${var.dnsimple_email}"
  token = "${var.dnsimple_token}"
}

resource "template_file" "member" {
  count = "${var.etcd_count}"
  template = "${file("etcd/cloud-config.tpl")}"
  vars {
    domain = "${var.dnsimple_domain}"
    name = "${format("${var.cluster_name}-%02d", count.index)}"
  }
}

resource "digitalocean_droplet" "member" {
  count = "${var.etcd_count}"
  name = "${format("${var.cluster_name}-%02d", count.index)}"
  image = "coreos-${var.coreos_channel}"
  region = "${var.instance_do_region}"
  size = "${var.instance_size}"
  ssh_keys = ["${var.ssh_fingerprint}"]
  user_data = "${element(template_file.member.*.rendered, count.index)}"
  private_networking = "true"
}
/*
resource "packet_device" "member" {
  count = "${var.etcd_count}"
  hostname = "${format("${var.cluster_name}-%02d", count.index)}"
  plan = "baremetal_0"
  facility = "${var.instance_packet_region}"
  operating_system = "coreos_${var.coreos_channel}"
  billing_cycle = "hourly"
  project_id = "${var.packet_project_id}"
}
*/
resource "dnsimple_record" "hostnames" {
  count = "${var.etcd_count}"
  domain = "${var.dnsimple_domain}"
  name = "${format("${var.cluster_name}-%02d", count.index)}"
  value = "${element(digitalocean_droplet.member.*.ipv4_address, count.index)}"
  type = "A"
  ttl = 60
}

resource "dnsimple_record" "vault" {
  count = "${var.etcd_count}"
  domain = "${var.dnsimple_domain}"
  name = "vault"
  value = "${element(digitalocean_droplet.member.*.ipv4_address, count.index)}"
  type = "A"
  ttl = 60
}

resource "dnsimple_record" "etcd_server_discovery" {
  count = "${var.etcd_count}"
  domain = "${var.dnsimple_domain}"
  name = "_etcd-server._tcp"
  value = "0 2380 ${element(digitalocean_droplet.member.*.ipv4_address_private, count.index)}"
  type = "SRV"
  ttl = 60
}

resource "dnsimple_record" "etcd_client_discovery" {
  count = "${var.etcd_count}"
  domain = "${var.dnsimple_domain}"
  name = "_etcd-client._tcp"
  value = "0 2379 ${element(digitalocean_droplet.member.*.ipv4_address_private, count.index)}"
  type = "SRV"
  ttl = 60
}

resource "dnsimple_record" "etcd_client_ssl_discovery" {
  count = "${var.etcd_count}"
  domain = "${var.dnsimple_domain}"
  name = "_etcd-client-ssl._tcp"
  value = "0 2379 ${format("${var.cluster_name}-%02d.${var.dnsimple_domain}", count.index)}"
  type = "SRV"
  ttl = 60
}