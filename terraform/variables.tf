variable "project_id" {
  description = "GCP 프로젝트 ID"
  type        = string
}

variable "region" {
  description = "GCP 리전"
  type        = string
  default     = "asia-northeast3" # 서울 리전
}

variable "cluster_name" {
  description = "GKE 클러스터 이름"
  type        = string
  default     = "my-gke"
}

variable "machine_type" {
  description = "GKE 노드의 머신 타입"
  type        = string
  default     = "e2-medium"
}

variable "desired_size" {
  description = "기본 노드 수"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "오토스케일 최소 노드 수"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "오토스케일 최대 노드 수"
  type        = number
  default     = 4
}
