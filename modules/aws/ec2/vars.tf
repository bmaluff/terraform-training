variable "servers" {
  type = any
  default = {}
}

variable "vpc_id" {
  type = string
  default = ""
  description = "ID of the VPC"
}