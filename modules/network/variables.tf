variable "name" {
  type        = string
  description = "Name of the VPC"
}

variable "subnetworks" {
  type = list(object({
    name_affix    = string
    region        = string
    ip_cidr_range = string
    secondary_ip_range = list(object({
      range_name    = string
      ip_cidr_range = string
    }))
  }))
  description = "List of the subnetworks of the VPC"
}

variable "project_id" {
  type        = string
  description = "Project id where to deploy the network"
}