variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "europe-west1"
}

variable "cluster_name" {
  type = string
}

variable "tenant" {
  type = string

  validation {
    condition     = contains(["t1-front", "t2-back", "t3-db"], var.tenant)
    error_message = "tenant must be t1-front, t2-back, or t3-db."
  }
}

variable "app_name" {
  type = string
}

variable "replicas" {
  type    = number
  default = 1
}

variable "image" {
  type    = string
  default = "python:3.12-alpine"
}

variable "http_port" {
  type    = number
  default = 8080
}

variable "probe_interval_seconds" {
  type    = number
  default = 30
}

variable "targets_allow" {
  type    = list(string)
  default = []
}

variable "targets_deny" {
  type    = list(string)
  default = []
}
