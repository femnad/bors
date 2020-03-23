variable managed_zone {}
variable project {}
variable service_account_file {}
variable tag {}

variable cloud_run_location {
  default = "europe-west1"
}
variable region {
  default = "europe-west-2"
}
variable zone {
  default = "europe-west2-c"
}

variable dns_records {
  type = set(string)
  default = ["run.fcd.dev", "b8s.fcd.dev"]
}
