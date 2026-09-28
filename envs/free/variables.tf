variable "my_ip_cidr" {
  type        = string
  description = "Your home IP as x.x.x.x/32"
}

variable "key_name" {
  type    = string
  default = "secureshop-key"
}

variable "lab_instance_type" {
  type    = string
  default = "m7i-flex.large"
}
