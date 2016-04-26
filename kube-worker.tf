resource "template_file" "worker" {
  count = "${var.worker_count}"
  template = "${file("kubernetes-worker/cloud-config.yml")}"
  vars {
    domain = "${var.dnsimple_domain}"
    name = "${format("${var.worker_name}-%02d", count.index)}"
    api_servers = "${join(",", formatlist("https://%s:443", digitalocean_droplet.master.*.ipv4_address_private))}`"
    reboot_strategy = "${var.reboot_strategy}"
  }
}

resource "digitalocean_droplet" "worker" {
  count = "${var.worker_count}"
  name = "${format("${var.worker_name}-%02d", count.index)}.${var.dnsimple_domain}"
  image = "coreos-${var.coreos_channel}"
  region = "${var.instance_region}"
  size = "${var.instance_size}"
  ssh_keys = ["${var.ssh_fingerprint}"]
  user_data = "${element(template_file.worker.*.rendered, count.index)}"
  private_networking = "true"
}

resource "dnsimple_record" "worker" {
  count = "${var.worker_count}"
  domain = "${var.dnsimple_domain}"
  name = "${format("${var.worker_name}-%02d", count.index)}"
  value = "${element(digitalocean_droplet.worker.*.ipv4_address, count.index)}"
  type = "A"
  ttl = 60
}
