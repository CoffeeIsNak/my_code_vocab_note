variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "cluster_name" {
  description = "GKE Cluster Name"
  type        = string
}

variable "machine_type" {
  description = "GKE Node Machine Type"
  type        = string
  default     = "e2-standard-2"
}

variable "min_size" {
  description = "GKE Node Pool Min Size"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "GKE Node Pool Max Size"
  type        = number
  default     = 6
}

variable "desired_size" {
  description = "GKE Node Pool Initial Size"
  type        = number
  default     = 2
}

variable "db_password" {
  description = "Cloud SQL User Password"
  type        = string
  sensitive   = true
}
