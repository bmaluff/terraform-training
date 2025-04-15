output "role_arn" {
  value = {for k, v in aws_iam_role.iam_role : k => v.arn}
}
 
output "user_arn" {
  value = {for k, v in aws_iam_user.user : k => v.arn}
}

output "instance_profile_arn" {
  value = {for k, v in aws_iam_instance_profile.this : k => v.arn}  
}

output "instance_profile_id" {
  value = {for k, v in aws_iam_instance_profile.this : k => v.id}  
}

output "instance_profile_name" {
  value = {for k, v in aws_iam_instance_profile.this : k => v.name}  
}
