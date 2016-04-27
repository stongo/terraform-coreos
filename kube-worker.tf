resource "template_file" "worker" {
  count = "${var.worker_count}"
  template = "${file("kubernetes-worker/cloud-config.yml")}"
  vars {
    domain = "${var.dnsimple_domain}"
    name = "${format("${var.worker_name}-%02d", count.index)}"
    reboot_strategy = "${var.reboot_strategy}"
  }
}

resource "packet_device" "worker" {
  count = "${var.worker_count}"
  hostname = "${format("${var.worker_name}-%02d", count.index)}.${var.dnsimple_domain}"
  project_id = "${var.packet_project}"
  operating_system = "coreos_${var.coreos_channel}"
  facility = "${var.instance_facility}"
  plan = "${var.instance_type}"
  billing_cycle = "hourly"
  user_data = "${element(template_file.worker.*.rendered, count.index)}"
}

resource "dnsimple_record" "worker" {
  count = "${var.worker_count}"
  domain = "${var.dnsimple_domain}"
  name = "${format("${var.worker_name}-%02d", count.index)}"
  value = "${element(packet_device.worker.*.network.0.address, count.index)}"
  type = "A"
  ttl = 60
}

resource "dnsimple_record" "worker_rr" {
  count = "${var.worker_count}"
  domain = "${var.dnsimple_domain}"
  name = "worker"
  value = "${element(packet_device.worker.*.network.0.address, count.index)}"
  type = "A"
  ttl = 60
}
