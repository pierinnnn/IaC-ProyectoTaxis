resource "aws_wafv2_web_acl" "api_waf_acl" {
  name        = "api-waf-acl"
  description = "WAF para proteger el API Gateway"
  scope       = "REGIONAL" # Para API Gateway o ALB, siempre "REGIONAL"
  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "apiWaf"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "limit-requests"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 1000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "limitRequests"
      sampled_requests_enabled   = true
    }
  }
}

resource "aws_wafv2_web_acl_association" "api_waf_assoc" {
  resource_arn = "arn:aws:apigateway:us-east-2::/restapis/${aws_api_gateway_rest_api.api.id}/stages/${aws_api_gateway_deployment.api_deploy.stage_name}"
  web_acl_arn  = aws_wafv2_web_acl.api_waf_acl.arn
}





