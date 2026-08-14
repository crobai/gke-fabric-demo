variable "project_id" {
  description = "GCP project ID for the DEV platform PoC (fleet host = this project)."
  type        = string
}

variable "region" {
  description = "Region for the subnet and Standard cluster control plane."
  type        = string
  default     = "europe-west1"
}

variable "cluster_name" {
  description = "GKE Standard cluster name (shared multi-tenant workload cluster)."
  type        = string
  default     = "gke-fabric-demo"
}

variable "release_channel" {
  description = "GKE release channel for the Standard cluster."
  type        = string
  default     = "REGULAR"

  validation {
    condition     = contains(["RAPID", "REGULAR", "STABLE"], var.release_channel)
    error_message = "release_channel must be RAPID, REGULAR, or STABLE."
  }
}

variable "network_name" {
  description = "Existing VPC network name (project VPC approximation — default VPC for this demo)."
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

variable "fleet" {
  description = <<-EOT
    Fleet (GKE Hub) settings for the platform cluster.
    One fleet per GCP project; this PoC uses the same project as fleet host.
    Membership is created via Standard fleet_project (gke.tf). The thin
    gke-hub module (fleet.tf) is wired for later features — do not also put
    this cluster in hub.clusters or Hub will reject a duplicate membership.
  EOT
  type = object({
    enabled      = optional(bool, true)
    host_project = optional(string) # defaults to var.project_id
  })
  default = {
    enabled = true
  }
}

variable "standard" {
  description = <<-EOT
    IDP catalog-shaped Standard flavor knobs (Fabric gke-cluster-standard + gke-nodepool).
    Playable: machine_type (resources), max_pods_per_node (density), min/max_nodes (autoscaling).
  EOT
  type = object({
    dataplane_v2      = optional(bool, true)
    max_pods_per_node = optional(number, 32)
    # Single zone keeps regional CP cheap for the PoC (still a regional cluster).
    node_locations = optional(list(string), ["europe-west1-b"])
    access = optional(object({
      private_nodes = optional(bool, true)
      dns_endpoint  = optional(bool, true)
    }), {})
    node_pool = optional(object({
      name              = optional(string, "default")
      machine_type      = optional(string, "e2-standard-2")
      disk_type         = optional(string, "pd-balanced")
      disk_size_gb      = optional(number, 30)
      max_pods_per_node = optional(number) # defaults to standard.max_pods_per_node
      min_nodes         = optional(number, 1)
      max_nodes         = optional(number, 3)
    }), {})
  })
  default = {}
}
