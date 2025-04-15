output "name" {
  value = aws_lb.this.name
}

output "sg_id" {
  value = aws_security_group.this.id
}

# output "alb_listener_arn" {
#   value = aws_lb_listener.alb_https_listener.arn
# }

output "alb_http_listener_arn" {
  value = aws_lb_listener.http.arn
}

output "alb_https_listener_arn" {
  value = aws_lb_listener.https.arn
}

output "alb_arn" {
  value = aws_lb.this.arn
}

output "alb_zone_id" {
  value = aws_lb.this.zone_id
}

output "alb_arn_suffix" {
  value = aws_lb.this.arn_suffix
}

output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "target_group_arn" {
  value = { for k, v in aws_lb_target_group.this : k => v.arn }
}

output "full_details" {
  value = aws_lb.this
}