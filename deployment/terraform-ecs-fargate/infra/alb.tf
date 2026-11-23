resource "aws_lb" "sequin-main" {
  enable_http2       = "true"
  name               = "sequin-main-lb"
  idle_timeout       = "60"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sequin-alb-sg.id]
  subnets            = [data.aws_subnet.sequin-public-primary.id, data.aws_subnet.sequin-public-secondary.id]

  ip_address_type = "ipv4"
}

resource "aws_lb_listener" "sequin-main-80" {
  load_balancer_arn = aws_lb.sequin-main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      host        = "#{host}"
      path        = "/#{path}"
      port        = "443"
      protocol    = "HTTPS"
      query       = "#{query}"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "sequin-main-443" {
  load_balancer_arn = aws_lb.sequin-main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.sequin_console.certificate_arn

  # Google sign-in in front of the console (see console_oidc.tf).
  dynamic "default_action" {
    for_each = var.console_oidc_enabled ? [1] : []
    content {
      type  = "authenticate-oidc"
      order = 1

      authenticate_oidc {
        issuer                     = "https://accounts.google.com"
        authorization_endpoint     = "https://accounts.google.com/o/oauth2/v2/auth"
        token_endpoint             = "https://oauth2.googleapis.com/token"
        user_info_endpoint         = "https://openidconnect.googleapis.com/v1/userinfo"
        client_id                  = local.console_oidc.client_id
        client_secret              = local.console_oidc.client_secret
        scope                      = "openid email"
        session_timeout            = 43200
        on_unauthenticated_request = "authenticate"
        authentication_request_extra_params = {
          hd = "prophero.com"
        }
      }
    }
  }

  default_action {
    type             = "forward"
    order            = var.console_oidc_enabled ? 2 : 1
    target_group_arn = aws_lb_target_group.sequin-main.arn
  }
}

resource "aws_lb_target_group" "sequin-main" {
  name                 = "sequin-main-tg"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.sequin-main.id
  deregistration_delay = 60

  health_check {
    enabled             = "true"
    healthy_threshold   = "2"
    interval            = "30"
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = "5"
    unhealthy_threshold = "5"
  }

  target_type     = "ip"
  ip_address_type = "ipv4"

  stickiness {
    cookie_duration = "86400"
    enabled         = "false"
    type            = "lb_cookie"
  }

  load_balancing_algorithm_type     = "round_robin"
  load_balancing_cross_zone_enabled = "use_load_balancer_configuration"
  protocol_version                  = "HTTP1"
  slow_start                        = "0"
}
