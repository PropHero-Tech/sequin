# Google sign-in (PropHero Workspace only) in front of the Sequin web console.
#
# Off by default. When console_oidc_enabled = true:
#   - every path on the HTTPS listener asks for a Google login first, and
#   - /api/* and /health skip the login, because the Sequin management API,
#     the CLI and health checks use them without a browser.
#
# The Google OAuth client lives in Google Cloud project "internal-sso"
# (Workspace, consent screen "Internal"). Its redirect URI must include
#   https://console.sequin.prophero.com/oauth2/idpresponse
# The client ID and secret are read from Secrets Manager, never from code:
#   secret "sequin/console-oidc" = {"client_id": "...", "client_secret": "..."}

variable "console_oidc_enabled" {
  type        = bool
  default     = false
  description = "Require Google sign-in (PropHero Workspace) for the Sequin console. /api/* and /health stay open."
}

data "aws_secretsmanager_secret_version" "console_oidc" {
  count     = var.console_oidc_enabled ? 1 : 0
  secret_id = "sequin/console-oidc"
}

locals {
  console_oidc = var.console_oidc_enabled ? jsondecode(data.aws_secretsmanager_secret_version.console_oidc[0].secret_string) : null
}

# API and health check: no login, straight to Sequin.
resource "aws_lb_listener_rule" "sequin_api_no_login" {
  count        = var.console_oidc_enabled ? 1 : 0
  listener_arn = aws_lb_listener.sequin-main-443.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sequin-main.arn
  }

  condition {
    path_pattern {
      values = ["/api/*", "/health"]
    }
  }
}
