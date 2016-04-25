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

resource "template_file" "worker" {
  count = "${var.worker_count}"
  template = "${file("kubernetes-worker/cloud-config.tpl")}"
  vars {
    domain = "${var.dnsimple_domain}"
    name = "${format("${var.worker_name}-%02d", count.index)}"
    etcd_endpoints = "${join(",", formatlist("http://%s.%s:2379", digitalocean_droplet.member.*.name, var.domain))}`"
    api_endpoints = "${join(",", formatlist("http://%s:8080", digitalocean_droplet.master.*.ipv4_address_private))}`"
  }
}

resource "digitalocean_droplet" "worker" {
  count = "${var.worker_count}"
  name = "${format("${var.master_name}-%02d", count.index)}"
  image = "coreos-${var.coreos_channel}"
  region = "${var.instance_do_region}"
  size = "${var.instance_packet_size}"
  ssh_keys = ["${var.ssh_fingerprint}"]
  user_data = "${element(template_file.worker.*.rendered, count.index)}"
  private_networking = "true"
}

#resource "packet_device" "worker" {
#  count = "${var.worker_count}"
#  hostname = "${format("${var.master_name}-%02d", count.index)}"
#  plan = "baremetal_0"
#  facility = "${var.instance_packet_region}"
#  operating_system = "coreos_${var.coreos_channel}"
#  billing_cycle = "hourly"
#  project_id = "${var.packet_project_id}"
#}
