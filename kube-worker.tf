resource "template_file" "worker" {
  count = "${var.worker_count}"
  template = "${file("kubernetes-worker/cloud-config.tpl")}"
  vars {
    domain = "${var.dnsimple_domain}"
    name = "${format("${var.worker_name}-%02d", count.index)}"
    etcd_endpoints = "${join(",", formatlist("http://%s.%s:2379", digitalocean_droplet.member.*.name, var.dnsimple_domain))}`"
    api_endpoints = "${join(",", formatlist("http://%s:8080", digitalocean_droplet.master.*.ipv4_address_private))}`"
    reboot_strategy = "${var.reboot_strategy}"
  }
}

resource "digitalocean_droplet" "worker" {
  count = "${var.worker_count}"
  name = "${format("${var.master_name}-%02d", count.index)}.${var.dnsimple_domain}"
  image = "coreos-${var.coreos_channel}"
  region = "${var.instance_do_region}"
  size = "${var.instance_size}"
  ssh_keys = ["${var.ssh_fingerprint}"]
  user_data = "${element(template_file.worker.*.rendered, count.index)}"
  private_networking = "true"
}
