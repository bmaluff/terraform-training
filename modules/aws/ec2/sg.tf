locals {
  sec_groups = {
    for server, server_info in var.servers : server => {
      name        = server_info.name
      description = "Sec Group for ${server_info.name}"
      vpc_id      = var.vpc_id
      ingress_rules = server_info.security_group.ingress_rules
      egress_rules = server_info.security_group.egress_rules
      tags = try(server_info.tags, {})
    }
  }
}
resource "aws_security_group" "sg" {
  for_each = local.sec_groups
  name        = each.value.name
  description = try(each.value.description, "Security group for ECS service")
  vpc_id      = each.value.vpc_id

  dynamic "ingress" {
    for_each = each.value.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = try(ingress.value.cidr_blocks, null)
      security_groups = try(ingress.value.security_groups, null)
      description = try(ingress.value.description, null)
      self = try(ingress.value.security_groups, null) == null && try(ingress.value.cidr_blocks, null) == null ? true : false
    }
  }

  dynamic "egress" {
    for_each = each.value.egress_rules
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = try(egress.value.cidr_blocks, null)
      security_groups = try(egress.value.security_groups, null)
      description = try(egress.value.description, null)
      self = try(egress.value.security_groups, null) == null && try(egress.value.cidr_blocks, null) == null ? true : false
    }
    
  }
  tags = each.value.tags
}
