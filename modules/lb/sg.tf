############################# Shared ##################################
resource "aws_security_group" "this" {
  name        = "SG for ${var.name}"
  description = "controls access to the ALB"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.sg_ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = try(ingress.value.cidr_blocks, [])
      security_groups = try(ingress.value.security_groups, [])
      description = try(ingress.value.description, "")
      ipv6_cidr_blocks = try(ingress.value.ipv6_cidr_blocks, [])
      prefix_list_ids = try(ingress.value.prefix_list_ids, [])
      self = try(ingress.value.cidr_blocks,[]) == [] && try(ingress.value.security_groups,[]) == [] ? true : false
    }
  }

  dynamic "egress" {
    for_each = var.sg_egress_rules
    content {
      protocol = egress.value.protocol
      from_port = egress.value.from_port
      to_port = egress.value.to_port
      cidr_blocks = try(egress.value.cidr_blocks, [])
      security_groups = try(egress.value.security_groups, [])
      description = try(egress.value.description, "")
      ipv6_cidr_blocks = try(egress.value.ipv6_cidr_blocks, [])
      prefix_list_ids = try(egress.value.prefix_list_ids, [])
      self = try(egress.value.cidr_blocks, []) == [] && try(egress.value.security_groups,[]) == [] ? true : false
    }
  }
  tags = var.sg_tags
}