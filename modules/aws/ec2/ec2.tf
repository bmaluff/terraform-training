locals {
  servers_with_eip = { for server, server_info in var.servers :
    server => server_info.name if try(server_info.attach_eip, false) == true
  }
}

resource "aws_instance" "this" {
  for_each                    = var.servers
  ami                         = each.value.ami
  instance_type               = each.value.instance_type
  tags                        = merge({ Name = each.value.name }, try(each.value.tags, {}))
  key_name                    = each.value.key_name
  subnet_id                   = each.value.subnet_id
  iam_instance_profile        = each.value.iam_instance_profile
  vpc_security_group_ids      = flatten([[aws_security_group.sg[each.key].id], try(each.value.vpc_security_group_ids, [])])
  user_data                   = each.value.user_data
  associate_public_ip_address = try(each.value.associate_public_ip_address, false)
  root_block_device {
    encrypted             = true
    volume_type           = try(each.value.root_block[0].volume_type, "gp3")
    kms_key_id            = try(each.value.root_block[0].kms_key_id, null)
    volume_size           = try(each.value.root_block[0].volume_size, 15)
    throughput            = try(each.value.root_block[0].throughput, 200)
    delete_on_termination = try(each.value.root_block[0].delete_on_termination, true)
    tags                  = merge({ Description = "Root block for ${each.value.name}" }, try(each.value.root_block[0].tags, {}))
  }
  user_data_replace_on_change = try(each.value.user_data_replace_on_change, true)
  dynamic "metadata_options" {
    for_each = length(try(each.value.metadata_options, [])) <= 1 ? try(each.value.metadata_options, []) : []
    content {
      http_tokens = try(metadata_options.value.http_tokens, null)
      http_put_response_hop_limit = try(metadata_options.value.http_put_response_hop_limit, null)
      http_endpoint = try(metadata_options.value.http_endpoint, null)
      http_protocol_ipv6 = try(metadata_options.value.http_protocol_ipv6, null)
      instance_metadata_tags = try(metadata_options.value.instance_metadata_tags, null)
    }
  }
  lifecycle {
    ignore_changes = [
      associate_public_ip_address,
      ami
    ]
  }
}

# Generate SSH key pair locally
# This is a workaround for the issue with AWS key pairs
resource "tls_private_key" "this" {
  for_each  = var.servers
  algorithm = try(each.value.key_pair[0].algorithm, "RSA")
  rsa_bits  = try(each.value.key_pair[0].rsa_bits, 2048)
}

# Output the private key to a file
resource "null_resource" "save_private_key" {
  for_each = var.servers
  provisioner "local-exec" {
    command = <<EOT
echo '${tls_private_key.this[each.key].private_key_pem}' > ${each.value.key_name}.pem
chmod 600 ${each.value.key_name}.pem
EOT
  }
}

# Output the public key to a file
resource "null_resource" "save_public_key" {
  for_each = var.servers
  provisioner "local-exec" {
    command = <<EOT
echo '${tls_private_key.this[each.key].public_key_openssh}' > public_key_${each.value.key_name}.pub
EOT
  }
}

# Associate the public key with an EC2 key pair
resource "aws_key_pair" "this" {
  for_each   = var.servers
  key_name   = each.value.key_name
  public_key = tls_private_key.this[each.key].public_key_openssh
}
