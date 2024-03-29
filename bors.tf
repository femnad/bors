terraform {
  backend gcs {}
}

provider "google" {
  project     = var.project
  region      = var.region
  zone        = var.zone
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
    annotations = {
      "client.knative.dev/user-image" = "gcr.io/foolproj/bors:${var.tag}"
    }
    labels = {
      "cloud.googleapis.com/location" = "europe-west1"
    }
    namespace = "foolproj"
  }

  template {
    spec {

      containers {
        image = "gcr.io/${var.project}/bors:${var.tag}"

        resources {
          limits = {
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
  location = google_cloud_run_service.bors.location
  project  = google_cloud_run_service.bors.project
  service  = google_cloud_run_service.bors.name

  policy_data = data.google_iam_policy.noauth.policy_data
}

resource "google_dns_record_set" "ghs-cname" {
  type = "CNAME"
  ttl  = 60

  managed_zone = var.managed_zone

  rrdatas = ["ghs.googlehosted.com."]

  for_each = var.dns_records

  name = format("%s.", each.value)
}

resource "google_cloud_run_domain_mapping" "bors-mapping" {
  location = var.cloud_run_location
  metadata {
    namespace = var.project
  }

  spec {
    route_name = google_cloud_run_service.bors.name
  }

  for_each = var.dns_records

  name = each.value
}
