resource "template_file" "master" {
  count = "${var.master_count}"
  template = "${file("kubernetes-master/cloud-config.yml")}"
  vars {
    domain = "${var.dnsimple_domain}"
    name = "${format("${var.master_name}-%02d", count.index)}"
    reboot_strategy = "${var.reboot_strategy}"
  }
}

resource "packet_device" "master" {
  count = "${var.master_count}"
  hostname = "${format("${var.master_name}-%02d", count.index)}.${var.dnsimple_domain}"
  project_id = "${var.packet_project}"
  operating_system = "coreos_${var.coreos_channel}"
  facility = "${var.instance_facility}"
  plan = "${var.instance_type}"
  billing_cycle = "hourly"
  user_data = "${element(template_file.master.*.rendered, count.index)}"
}

resource "dnsimple_record" "master" {
  count = "${var.master_count}"
  domain = "${var.dnsimple_domain}"
  name = "${format("${var.master_name}-%02d", count.index)}"
  value = "${element(packet_device.master.*.network.0.address, count.index)}"
  type = "A"
  ttl = 60
}

resource "dnsimple_record" "master_rr" {
  count = "${var.master_count}"
  domain = "${var.dnsimple_domain}"
  name = "master"
  value = "${element(packet_device.master.*.network.0.address, count.index)}"
  type = "A"
  ttl = 60
}

resource "dnsimple_record" "master_internal_rr" {
  count = "${var.master_count}"
  domain = "${var.dnsimple_domain}"
  name = "master-internal"
  value = "${element(packet_device.master.*.network.2.address, count.index)}"
  type = "A"
  ttl = 60
}

resource "dnsimple_record" "server_discovery" {
  count = "${var.master_count}"
  domain = "${var.dnsimple_domain}"
  name = "_etcd-server._tcp"
  value = "0 2380 ${element(packet_device.master.*.network.2.address, count.index)}"
  type = "SRV"
  ttl = 60
}

resource "dnsimple_record" "client_discovery" {
  count = "${var.master_count}"
  domain = "${var.dnsimple_domain}"
  name = "_etcd-client._tcp"
  value = "0 2379 ${element(packet_device.master.*.network.2.address, count.index)}"
  type = "SRV"
  ttl = 60
}
