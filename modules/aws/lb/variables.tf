################################## Global #######################################
variable "active_aws_region" {
  default = "us-east-1"
}

variable "vpc_id" {
  type = string
}
############################################# ALB #############################################
variable "name" {
  type = string
}
variable "subnets" {
  type = list(string)
}

variable "load_balancer_type" {
  type = string
  default = "application"
}
variable "idle_timeout" {
  type = number
  default = 60
}

variable "internal" {
  type = bool
  default = false
}

variable "access_logs" {
  type = any
  default = []
}

variable "ip_address_type" {
  type = string
  default = "ipv4"
}

variable "enable_deletion_protection" {
  type = bool
  default = false
}

variable "enable_http2" {
  type = bool
  default = true
}

variable "enable_cross_zone_load_balancing" {
  type = bool
  default = true
}

variable "customer_owned_ipv4_pool" {
  type = string
  default = null
}

variable "xff_header_processing_mode" {
  type = string
  default = "append"
}

variable "lb_tags" {
  type = map(string)
  default = {}
}

variable "drop_invalid_header_fields" {
  type = bool
  default = false
}

variable "enable_tls_version_and_cipher_suite_headers" {
  type = bool
  default = false
}

variable "enable_waf_fail_open" {
  type = bool
  default = false
}

variable "enable_xff_client_port" {
  type = bool
  default = false
}

variable "preserve_host_header" {
  type = bool
  default = false
}

variable "subnet_mapping" {
  type = any
  default = []
}

variable "desync_mitigation_mode" {
  type = string
  default = "defensive"
}

variable "access_logs_enabled" {
  type = bool
  default = false
}

variable "access_logs_bucket" {
  type = string
  default = "null"
}

variable "access_logs_prefix" {
  type = string
  default = ""
}

variable "http_listener_port" {
  type = number
  default = 80
}
variable "https_listener_port" {
  type = number
  default = 443
}

variable "https_listener_ssl_policy" {
  type = string
  default = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "https_listener_certificate_arn" {
  type = string
}

variable "extra_certificates" {
  type = any
  default = {} 
}

variable "listener_rules" {
  type = any
  default = {}
}

variable "target_groups" {
  type = any
  default = {}
}

############################################## SG #####################################
variable "sg_tags" {
  type = map(string)
  default = {}
}

variable "sg_ingress_rules" {
  type = any
  default = []
}

variable "sg_egress_rules" {
  type = any
  default = [{
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }]
}