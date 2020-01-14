terraform {
  backend gcs { }
}

variable project {}

variable service_account_file {}

variable region {
  default = "europe-west-2"
}

variable zone {
  default = "europe-west2-c"
}

variable cloud_run_location {
  default = "europe-west1"
}

resource "null_resource" "submit-build" {

  provisioner "local-exec" {
    command = "gcloud builds submit --config cloudbuild.yaml --substitutions=TAG_NAME=0.1.0 ."
  }

}

provider "google" {
  credentials = var.service_account_file
  project     = var.project
  region      = var.region
  zone = var.zone
}

resource "google_cloud_run_service" "bors" {
  name     = "bors-cloudrun-service"
  location = var.cloud_run_location

  template {
    spec {
      containers {
        image = "gcr.io/${var.project}/bors:0.1.0"
      }
    }
  }

}
