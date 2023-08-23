variable "name" {
  type = string
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
}