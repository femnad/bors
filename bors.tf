terraform {
  backend gcs {}
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

module "instance" {
  source      = "femnad/instance-module/gcp"
  version     = "0.7.6"
  github_user = "femnad"
  project     = var.project
  ssh_user    = var.ssh_user
  image       = "fedora-coreos-cloud/fedora-coreos-stable"
}

module "dns" {
  source           = "femnad/dns-module/gcp"
  version          = "0.3.1"
  dns_name         = "run.fcd.dev."
  instance_ip_addr = module.instance.instance_ip_addr
  managed_zone     = var.managed_zone
  project          = var.project
}
