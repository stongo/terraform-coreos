variable "cluster_name" {
  default = "etcd"
  description = "name for the cluster to create. hosts will have hostnames ${cluster-name}-##"
}

variable "do_token" {
  description = "api token for digitalocean"
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

variable "instance_region" {
  default = "nyc3"
  description = "region in which to create new instances"
}

variable "instance_count" {
  default = "3"
  description = "number of instances to create and add to the cluster"
}

variable "vault_url" {
  default = "https://releases.hashicorp.com/vault/0.5.2/vault_0.5.2_linux_amd64.zip"
  description = "url to download the (zipped) vault binary from"
}

variable "domain_key" {
  description = "path to file containing private key for valid domain certificate"
}

variable "domain_cert" {
  description = "path to file containing a valid domain certificate"
}
