resource "template_file" "master" {
  count = "${var.master_count}"
  template = "${file("kubernetes-master/cloud-config.tpl")}"
  vars {
    domain = "${var.dnsimple_domain}"
    name = "${format("${var.master_name}-%02d", count.index)}"
    etcd_endpoints = "${join(",", formatlist("http://%s.%s:2379", digitalocean_droplet.member.*.name, var.dnsimple_domain))}`"
    reboot_strategy = "${var.reboot_strategy}"
  }
}

resource "digitalocean_droplet" "master" {
  count = "${var.master_count}"
  name = "${format("${var.master_name}-%02d", count.index)}.${var.dnsimple_domain}"
  image = "coreos-${var.coreos_channel}"
  region = "${var.instance_do_region}"
  size = "${var.instance_size}"
  ssh_keys = ["${var.ssh_fingerprint}"]
  user_data = "${element(template_file.master.*.rendered, count.index)}"
  private_networking = "true"
}
