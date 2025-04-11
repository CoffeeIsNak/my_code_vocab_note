terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.17.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_client_config" "current" {}

# ---------------------- Cloud SQL ----------------------
resource "google_sql_database_instance" "airflow" {
  name             = "airflow-sql"
  database_version = "POSTGRES_14"
  region           = var.region
  deletion_protection = false

  settings {
    tier = "db-custom-2-8192"

    ip_configuration {
      ipv4_enabled    = true
    }
  }
}

resource "google_sql_user" "airflow" {
  name     = "airflow"
  instance = google_sql_database_instance.airflow.name
  password = var.db_password
}

resource "google_sql_database" "airflow_db" {
  name     = "airflowdb"
  instance = google_sql_database_instance.airflow.name
}

# ---------------------- Service Account & Key ----------------------
resource "google_service_account" "cloudsql_sa" {
  account_id   = "cloudsql-proxy-airflow"
  display_name = "CloudSQL Proxy SA"
}

resource "google_project_iam_member" "cloudsql_sa_binding" {
  role   = "roles/cloudsql.client"
  member = "serviceAccount:${google_service_account.cloudsql_sa.email}"
  project = var.project_id
}

resource "google_service_account_key" "cloudsql_sa_key" {
  service_account_id = google_service_account.cloudsql_sa.name
  private_key_type   = "TYPE_GOOGLE_CREDENTIALS_FILE"
}

resource "local_file" "cloudsql_key_file" {
  content  = base64decode(google_service_account_key.cloudsql_sa_key.private_key)
  filename = "../deploy/key.json"
}

# ---------------------- GKE ----------------------
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = "default"
  subnetwork = "default"

  deletion_protection = false
  ip_allocation_policy {}
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = var.desired_size

  node_config {
    machine_type = var.machine_type
    disk_size_gb = 30
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  autoscaling {
    min_node_count = var.min_size
    max_node_count = var.max_size
  }
}

# ---------------------- Providers for K8s/Helm ----------------------
provider "kubernetes" {
  host                   = "https://${google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.current.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = "https://${google_container_cluster.primary.endpoint}"
    token                  = data.google_client_config.current.access_token
    cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
  }
}

# ---------------------- Outputs ----------------------
output "cloudsql_instance_connection_name" {
  value = google_sql_database_instance.airflow.connection_name
}

output "cloudsql_user" {
  value = google_sql_user.airflow.name
}

output "cloudsql_db_name" {
  value = google_sql_database.airflow_db.name
}

output "cloudsql_sa_key" {
  value     = google_service_account_key.cloudsql_sa_key.private_key
  sensitive = true
}

output "cloudsql_sa_key_path" {
  value = local_file.cloudsql_key_file.filename
}

output "gke_cluster_name" {
  value = google_container_cluster.primary.name
}

output "gke_cluster_region" {
  value = var.region
}

output "project_id" {
  value = var.project_id
}
