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

resource "template_file" "master" {
  count = "${var.master_count}"
  etcd_count = "${var.etcd_count}"
  template = "${file("kubernetes-master/cloud-config.tpl")}"
  vars {
    domain = "${var.dnsimple_domain}"
    name = "${format("${var.master_name}-%02d", count.index)}"
    etcd_endpoints = "${join(",", formatlist("http://%s.%s:2379", digitalocean_droplet.member.*.name, var.domain))}`"
  }
}

resource "digitalocean_droplet" "master" {
  count = "${var.master_count}"
  name = "${format("${var.master_name}-%02d", count.index)}"
  image = "coreos-${var.coreos_channel}"
  region = "${var.instance_do_region}"
  size = "${var.instance_packet_size}"
  ssh_keys = ["${var.ssh_fingerprint}"]
  user_data = "${element(template_file.master.*.rendered, count.index)}"
  private_networking = "true"
}

#resource "packet_device" "master" {
#  count = "${var.master_count}"
#  hostname = "${format("${var.master_name}-%02d", count.index)}"
#  plan = "baremetal_0"
#  facility = "${var.instance_packet_region}"
#  operating_system = "coreos_${var.coreos_channel}"
#  billing_cycle = "hourly"
#  project_id = "${var.packet_project_id}"
#}
