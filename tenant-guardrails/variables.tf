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

variable "http_port" {
  type    = number
  default = 8080
}

variable "tenants" {
  type = map(object({
    team_principals = list(string)
    quota = object({
      pods   = string
      cpu    = string
      memory = string
    })
    allow_egress = optional(list(object({
      namespace = string
      port      = optional(number)
    })), [])
    allow_ingress_from = optional(list(string), [])
  }))
}
