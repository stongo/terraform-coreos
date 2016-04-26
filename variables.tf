# variables we need
variable "master_name" {
  default = "kube-master"
  description = "name prefix for the kubernetes masters. hosts will have hostnames ${master_name}-##"
}

variable "master_count" {
  default = "3"
  description = "number of instances to create and add to the kubernetes master cluster"
}

variable "worker_name" {
  default = "kube-worker"
  description = "prefix for the kubernetes worker hosts, hostnames will be ${worker_prefix}-${worker_labels[i]}-##"
}

variable "worker_count" {
  default = "3"
  description = "number of instances to add to the kubernetes cluster as workers"
}

variable "coreos_channel" {
  default = "beta"
  description = "release channel of coreos to use, can be one of: alpha beta stable"
}

variable "reboot_strategy" {
  default = "etcd-lock"
  description = "coreos reboot strategy"
}

variable "instance_size" {
  default = "512mb"
  description = "node size to create"
}

variable "instance_region" {
  default = "nyc3"
  description = "region in which to create new instances"
}

variable "do_token" {
  description = "api token for digitalocean"
}

# variable "packet_token" {
#   description = "api token for packet"
# }

variable "dnsimple_token" {
  description = "api token for dnsimple"
}

variable "dnsimple_email" {
  description = "email address associated with dnsimple account"
}

variable "dnsimple_domain" {
  description = "base domain to use for etcd discovery"
}

variable "ssh_fingerprint" {
  description = "fingerprint of (already saved) ssh key to add to instances"
}

## provider initialization goes here
provider "digitalocean" {
  token = "${var.do_token}"
}

# provider "packet" {
#   token = "${var.packet_token}"
# }

provider "dnsimple" {
  email = "${var.dnsimple_email}"
  token = "${var.dnsimple_token}"
}
