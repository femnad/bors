variable managed_zone {}
variable project {}
variable ssh_user {}

variable region {
  default = "europe-west-1"
}
variable zone {
  default = "europe-west1-c"
}

variable dns_records {
  type    = set(string)
  default = ["run.fcd.dev", "b8s.fcd.dev"]
}
