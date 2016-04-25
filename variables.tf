variable "cluster_name" {
  default = "etcd"
  description = "name for the cluster to create. hosts will have hostnames ${cluster-name}-##"
}

variable "master_name" {
  default = "kube-master"
  description = "name for the kubernetes master to create. hosts will have hostnames ${cluster-name}-##"
}

variable "worker_name" {
  default = "etcd"
  description = "name for the kubernetes worker to create. hosts will have hostnames ${cluster-name}-##"
}

variable "do_token" {
  description = "api token for digitalocean"
}

variable "packet_token" {
  description = "api token for packet"
}

variable "dnsimple_token" {
  description = "api token for dnsimple"
}

variable "dnsimple_email" {
  description = "email address associated with dnsimple account"
}

variable "dnsimple_domain" {
  description = "base domain to use for etcd discovery"
}

variable "coreos_channel" {
  default = "beta"
  description = "release channel of coreos to use, can be one of: alpha beta stable"
}

variable "ssh_fingerprint" {
  description = "fingerprint of (already saved) ssh key to add to instances"
}

variable "instance_size" {
  default = "512mb"
  description = "node size to create"
}

variable "instance_do_region" {
  default = "nyc3"
  description = "region in which to create new instances"
}

variable "instance_packet_region" {
  default = "ewr1"
  description = "region in which to create new instances"
}

variable "etcd_count" {
  default = "3"
  description = "number of instances to create and add to the etcd cluster"
}

variable "master_count" {
  default = "1"
  description = "number of instances to create and add to the kubernetes master cluster"
}

variable "worker_count" {
  default = "2"
  description = "number of instances to create and add to the kubernetes worker cluster"
}

variable "reboot_strategy" {
  default = "etcd-lock"
  description = "coreos reboot strategy"
}
