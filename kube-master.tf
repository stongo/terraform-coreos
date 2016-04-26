resource "template_file" "master" {
  count = "${var.master_count}"
  template = "${file("kubernetes-master/cloud-config.yml")}"
  vars {
    domain = "${var.dnsimple_domain}"
    name = "${format("${var.master_name}-%02d", count.index)}"
    reboot_strategy = "${var.reboot_strategy}"
  }
}

resource "digitalocean_droplet" "master" {
  count = "${var.master_count}"
  name = "${format("${var.master_name}-%02d", count.index)}.${var.dnsimple_domain}"
  image = "coreos-${var.coreos_channel}"
  region = "${var.instance_region}"
  size = "${var.instance_size}"
  ssh_keys = ["${var.ssh_fingerprint}"]
  user_data = "${element(template_file.master.*.rendered, count.index)}"
  private_networking = "true"
}

resource "dnsimple_record" "master" {
  count = "${var.master_count}"
  domain = "${var.dnsimple_domain}"
  name = "${format("${var.master_name}-%02d", count.index)}"
  value = "${element(digitalocean_droplet.master.*.ipv4_address, count.index)}"
  type = "A"
  ttl = 60
}

resource "dnsimple_record" "server_discovery" {
  count = "${var.master_count}"
  domain = "${var.dnsimple_domain}"
  name = "_etcd-server._tcp"
  value = "0 2380 ${element(digitalocean_droplet.master.*.ipv4_address_private, count.index)}"
  # value = "0 2380 ${format("_${var.master_name}-%02d.${var.dnsimple_domain}", count.index)}"
  type = "SRV"
  ttl = 60
}

resource "dnsimple_record" "client_discovery" {
  count = "${var.master_count}"
  domain = "${var.dnsimple_domain}"
  name = "_etcd-client._tcp"
  value = "0 2379 ${element(digitalocean_droplet.master.*.ipv4_address_private, count.index)}"
  # value = "0 2379 ${format("_${var.master_name}-%02d.${var.dnsimple_domain}", count.index)}"
  type = "SRV"
  ttl = 60
}
