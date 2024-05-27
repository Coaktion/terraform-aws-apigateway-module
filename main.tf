#####################################
# ------------ Gateway ------------ #
#####################################
resource "aws_api_gateway_rest_api" "this" {
  name = local.gateway_name
}

resource "aws_api_gateway_resource" "this" {
  for_each = local.api_resources

  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = each.value
}

resource "aws_api_gateway_authorizer" "this" {
  for_each = local.authorizer

  name          = each.value.name
  rest_api_id   = aws_api_gateway_rest_api.this.id
  type          = "COGNITO_USER_POOLS"
  provider_arns = each.value.provider_arns
}

resource "aws_api_gateway_stage" "this" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this_gtw_deployment.id
  stage_name    = var.api_gtw.stage
}

resource "aws_api_gateway_method_settings" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled                            = var.api_gtw.settings.metrics_enabled
    logging_level                              = var.api_gtw.settings.logging_level
    data_trace_enabled                         = var.api_gtw.settings.data_trace_enabled
    throttling_burst_limit                     = var.api_gtw.settings.throttling_burst_limit
    throttling_rate_limit                      = var.api_gtw.settings.throttling_rate_limit
    caching_enabled                            = var.api_gtw.settings.caching_enabled
    cache_ttl_in_seconds                       = var.api_gtw.settings.cache_ttl_in_seconds
    cache_data_encrypted                       = var.api_gtw.settings.cache_data_encrypted
    require_authorization_for_cache_control    = var.api_gtw.settings.require_authorization_for_cache_control
    unauthorized_cache_control_header_strategy = var.api_gtw.settings.unauthorized_cache_control_header_strategy
  }
}

resource "aws_api_gateway_deployment" "this_gtw_deployment" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeployment = sha1(jsonencode([
      local.lambda_resources,
      aws_api_gateway_integration_response.this_cors
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}
