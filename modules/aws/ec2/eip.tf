# resource block for eip #

resource "aws_eip" "this" {
    for_each = local.servers_with_eip
    domain = try(each.value.domain, "vpc")
    instance = aws_instance.this[each.key].id
    tags = merge({Description = "EIP for ${each.value}"}, try(each.value.tags, {}))
}

# resource block for ec2 and eip association #
resource "aws_eip_association" "eip_assoc" {
    for_each = local.servers_with_eip
  instance_id   = aws_instance.this[each.key].id
  allocation_id = aws_eip.this[each.key].id
}
