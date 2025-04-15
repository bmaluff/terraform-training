output "server_id" {
  value = {for k,v in aws_instance.this: k => v.id}
}

output "server_public_ip" {
  value = {for k,v in aws_instance.this: k => v.public_ip}
}

output "server_private_ip" {
  value = {for k,v in aws_instance.this: k => v.private_ip}
}

output "server_public_dns" {
  value = {for k,v in aws_instance.this: k => v.public_dns}
}

output "server_private_dns" {
  value = {for k,v in aws_instance.this: k => v.private_dns}
}

output "server_security_group" {
  value = {for k,v in aws_instance.this: k => v.security_groups}
}

output "server_subnet_id" {
  value = {for k,v in aws_instance.this: k => v.subnet_id}
}

output "server_vpc_security_group_ids" {
  value = {for k,v in aws_instance.this: k => v.vpc_security_group_ids}
}

output "server_ami" {
  value = {for k,v in aws_instance.this: k => v.ami}
}

output "server_instance_type" {
  value = {for k,v in aws_instance.this: k => v.instance_type}
}

output "server_iam_instance_profile" {
  value = {for k,v in aws_instance.this: k => v.iam_instance_profile}
}
