terraform {
  backend gcs { }
}

variable dns_name {}
variable mapped_domain {}
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

provider "google" {
  credentials = var.service_account_file
  project     = var.project
  region      = var.region
  zone = var.zone
}

resource "null_resource" "submit-build" {

  triggers = {
    tag_version = var.tag
  }

  provisioner "local-exec" {
    command = "gcloud builds submit --config cloudbuild.yaml --substitutions=TAG_NAME=${var.tag} ."
  }

}

resource "google_project_service" "run" {
  service = "run.googleapis.com"
}

resource "google_cloud_run_service" "bors" {
  depends_on = [null_resource.submit-build, google_project_service.run]

  name     = "bors-cloudrun-service"
  location = var.cloud_run_location

  traffic {
      latest_revision = true
      percent         = 100
  }

    metadata {
        annotations      = {
            "client.knative.dev/user-image"    = "gcr.io/foolproj/bors:${var.tag}"
        }
        labels           = {
            "cloud.googleapis.com/location" = "europe-west1"
        }
        namespace        = "foolproj"
    }

    template {
        spec {

            containers {
				image = "gcr.io/${var.project}/bors:${var.tag}"

                resources {
                    limits   = {
                        "cpu"    = "1000m"
                        "memory" = "256Mi"
                    }
                }
            }
        }
    }
}

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location    = google_cloud_run_service.bors.location
  project     = google_cloud_run_service.bors.project
  service     = google_cloud_run_service.bors.name

  policy_data = data.google_iam_policy.noauth.policy_data
}

resource "google_dns_record_set" "ghs-cname" {
  name = var.dns_name
  type = "CNAME"
  ttl  = 60

  managed_zone = var.managed_zone

  rrdatas = ["ghs.googlehosted.com."]
}

resource "google_cloud_run_domain_mapping" "bors-mapping" {
  location = var.cloud_run_location
  name     = var.mapped_domain

  metadata {
    namespace = var.project
  }

  spec {
    route_name = google_cloud_run_service.bors.name
  }
}

output "url" {
  value = "https://${var.mapped_domain}"
}
