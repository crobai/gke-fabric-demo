variable "project_id" {
  description = "GCP project ID for the demo cluster."
  type        = string
}

variable "region" {
  description = "Region for the subnet and Autopilot cluster."
  type        = string
  default     = "europe-west1"
}

variable "cluster_name" {
  description = "GKE Autopilot cluster name."
  type        = string
  default     = "gke-fabric-demo"
}

variable "network_name" {
  description = "Existing VPC network name (default VPC for this demo)."
  type        = string
  default     = "default"
}

variable "subnet_name" {
  description = "Subnet name for GKE nodes/pods/services."
  type        = string
  default     = "gke-subnet"
}

variable "subnet_cidr" {
  description = "Primary CIDR for the GKE subnet."
  type        = string
  default     = "10.10.0.0/20"
}

variable "pods_cidr" {
  description = "Secondary range CIDR for Pods."
  type        = string
  default     = "10.20.0.0/16"
}

variable "services_cidr" {
  description = "Secondary range CIDR for Services."
  type        = string
  default     = "10.30.0.0/20"
}
