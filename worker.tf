resource "template_file" "worker_create_certs" {
  count = "${var.worker_count}"
  template = "${file("worker/create_certs.sh")}"
  vars {
    name = "${format("${var.worker_name}-%02d", count.index)}"
  }
}

resource "template_file" "worker_kubeconfig" {
  count = "${var.worker_count}"
  template = "${file("worker/kubeconfig.yaml")}"
  vars {
    name = "${format("${var.worker_name}-%02d", count.index)}"
  }
}

resource "template_file" "worker_proxy" {
  template = "${file("worker/kube-proxy.yaml")}"
  vars {
    domain = "${var.dnsimple_domain}"
  }
}

resource "template_file" "worker" {
  count = "${var.worker_count}"
  template = "${file("worker/cloud-config.yaml")}"
  vars {
    domain = "${var.dnsimple_domain}"
    name = "${format("${var.worker_name}-%02d", count.index)}"
    reboot_strategy = "${var.reboot_strategy}"

    # manifests
    proxy = "${base64encode(template_file.worker_proxy.rendered)}"

    # certs
    ca = "${base64encode(file("ssl/ca.pem"))}"
    ca_key = "${base64encode(file("ssl/ca-key.pem"))}"

    # common
    ntp = "${base64encode(file("common/ntp.conf"))}"
    sshd = "${base64encode(file("common/sshd_config"))}"

    # worker specific
    create_certs = "${base64encode(element(template_file.worker_create_certs.*.rendered, count.index))}"
    kubeconfig = "${base64encode(element(template_file.worker_kubeconfig.*.rendered, count.index))}"
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
