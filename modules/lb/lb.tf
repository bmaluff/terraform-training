################ Shared Components ##################
resource "aws_lb" "this" {
  name               = var.name
  subnets            = var.subnets
  security_groups    = [ aws_security_group.this.id ]
  load_balancer_type = var.load_balancer_type
  internal = var.internal
  idle_timeout = var.idle_timeout
  desync_mitigation_mode = var.desync_mitigation_mode
  dynamic "access_logs" {
    for_each = var.access_logs
    content {
      enabled = access_logs.value.enabled
      bucket = access_logs.value.bucket
      prefix = access_logs.value.prefix
    }
  }
  ip_address_type = var.ip_address_type
  enable_deletion_protection = var.enable_deletion_protection
  enable_http2 = var.enable_http2
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  customer_owned_ipv4_pool = var.customer_owned_ipv4_pool
  xff_header_processing_mode = var.xff_header_processing_mode
  tags = var.lb_tags
  drop_invalid_header_fields = var.drop_invalid_header_fields
  enable_tls_version_and_cipher_suite_headers = var.enable_tls_version_and_cipher_suite_headers
  enable_waf_fail_open = var.enable_waf_fail_open
  enable_xff_client_port = var.enable_xff_client_port
  preserve_host_header = var.preserve_host_header
  # access_logs {
  #   enabled = var.access_logs_enabled
  #   bucket = var.access_logs_bucket
  #   prefix = var.access_logs_prefix
  # }
  lifecycle {
    ignore_changes = [
      security_groups
    ]
  }
}

#redirecting all incomming traffic from ALB to the target group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.id
  port              = var.http_listener_port
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      status_code = "HTTP_301"
      protocol = "HTTPS"
      port = var.https_listener_port
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.id
  port              = var.https_listener_port
  protocol          = "HTTPS"
  ssl_policy        = var.https_listener_ssl_policy #"ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.https_listener_certificate_arn
  #enable above 2 if you are using HTTPS listner and change protocal from HTTPS to HTTPS
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "application/json"
      message_body = "{Este es el final}"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener_rule" "this" {
  for_each = var.listener_rules
  listener_arn = aws_lb_listener.https.arn
  priority     = each.value.priority #100

  action {
    type             = "forward"
    #if you want to link target groups to the ALB, you need to create
    #listener rules var with the same key as the target groups
    target_group_arn = try(each.value.target_group_arn, aws_lb_target_group.this[each.key].arn)
  }
  condition {
    host_header {
      values = flatten([try(each.value.host_headers,[]), [aws_lb.this.dns_name]])
    }
  }
  dynamic "condition" {
    for_each = length(try(each.value.listener_rule_path_patterns, [])) > 0 ? [each.value.listener_rule_path_patterns] : []
    content {
      path_pattern {
        values = condition.value
      }
    }
    
  }

  dynamic "condition" {
    for_each = length(try(each.value.listener_rule_http_headers, [])) > 0 ? [each.value.listener_rule_http_headers] : []
    content {
      http_header {
        http_header_name = condition.value.http_header_name
        values = condition.value.values
      }
    }
  }
}

resource "aws_lb_listener_certificate" "extra_cert" {
  for_each = { for k,v in var.extra_certificates : k => v }
  listener_arn = aws_lb_listener.https.arn
  certificate_arn = each.value
}

resource "aws_lb_target_group" "this" {
  #if you want to link target groups to the ALB, you need to create
  #target_groups var with the same key as the listener rules
  for_each = var.target_groups
  name     = each.value.name
  port     = each.value.port
  protocol = each.value.protocol #HTTP
  deregistration_delay = try(each.value.deregistration_delay, 60) #60
  vpc_id   = each.value.vpc_id

  dynamic "health_check" {
    for_each = length(try([each.value.health_check], [])) == 1 ? [each.value.health_check] : []
    content {
      healthy_threshold   = try(health_check.value.healthy_threshold, 2)
      unhealthy_threshold = try(health_check.value.unhealthy_threshold, 3)
      timeout             = try(health_check.value.timeout, 10)
      protocol            = try(health_check.value.protocol, "HTTP") #"HTTP"
      matcher             = try(health_check.value.matcher, "200") #"200"
      path                = try(health_check.value.path,"/")
      interval            = try(health_check.value.interval, 30)
      port                = try(health_check.value.port, var.http_listener_port)
    }
  }
  dynamic "stickiness" {
    for_each = length(try([each.value.stickiness], [])) == 1 ?  [each.value.stickiness] : []
    content {
      enabled = try(stickiness.value.enabled, false)
      type    = try(stickiness.value.type,  "lb_cookie")
      cookie_duration = try(stickiness.value.cookie_duration, 86400)
    }
  }
}
