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
  version     = "0.7.7"
  github_user = "femnad"
  project     = var.project
  ssh_user    = var.ssh_user
}

module "dns" {
  source           = "femnad/dns-module/gcp"
  version          = "0.3.1"
  dns_name         = "run.fcd.dev."
  instance_ip_addr = module.instance.instance_ip_addr
  managed_zone     = var.managed_zone
  project          = var.project
}

module "firewall-module" {
  source  = "femnad/firewall-module/gcp"
  version = "0.2.3"
  network = module.instance.network_name
  project          = var.project
  self_reachable = {
    "8080" = "tcp"
  }
  world_reachable = {
    "80,443" = "tcp"
  }
}
