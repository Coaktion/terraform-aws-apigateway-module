# -------------------------- gateway --------------------------
resource "aws_api_gateway_rest_api" "this" {
  for_each = local.gateways

  name = each.value.name
}

resource "aws_api_gateway_resource" "this" {
  for_each = local.gateways

  parent_id   = aws_api_gateway_rest_api.this[each.key].root_resource_id
  path_part   = each.value.path
  rest_api_id = aws_api_gateway_rest_api.this[each.key].id
}

resource "aws_api_gateway_authorizer" "this" {
  for_each = tomap(var.cognito_authorizer != null ? { for gtw in local.gateways : gtw.name => var.cognito_authorizer } : {})

  name          = each.value.name
  rest_api_id   = aws_api_gateway_rest_api.this[each.key].id
  type          = "COGNITO_USER_POOLS"
  provider_arns = each.value.provider_arns
}

resource "aws_api_gateway_stage" "this" {
  for_each = local.gateways

  rest_api_id   = aws_api_gateway_rest_api.this[each.key].id
  stage_name    = each.value.stage
  deployment_id = aws_api_gateway_deployment.this_gtw_deployment[each.key].id
}

resource "aws_api_gateway_method_settings" "this" {
  for_each = local.gateways

  rest_api_id = aws_api_gateway_rest_api.this[each.key].id
  stage_name  = aws_api_gateway_stage.this[each.key].stage_name
  method_path = "*/*"

  settings {
    metrics_enabled                            = each.value.settings.metrics_enabled
    logging_level                              = each.value.settings.logging_level
    data_trace_enabled                         = each.value.settings.data_trace_enabled
    throttling_burst_limit                     = each.value.settings.throttling_burst_limit
    throttling_rate_limit                      = each.value.settings.throttling_rate_limit
    caching_enabled                            = each.value.settings.caching_enabled
    cache_ttl_in_seconds                       = each.value.settings.cache_ttl_in_seconds
    cache_data_encrypted                       = each.value.settings.cache_data_encrypted
    require_authorization_for_cache_control    = each.value.settings.require_authorization_for_cache_control
    unauthorized_cache_control_header_strategy = each.value.settings.unauthorized_cache_control_header_strategy
  }
}

resource "aws_api_gateway_deployment" "this_gtw_deployment" {
  for_each = local.gateways

  rest_api_id = aws_api_gateway_rest_api.this[each.key].id

  triggers = { // TODO review
    redeployment = sha1(jsonencode([
      local.lambda_resources,
      aws_api_gateway_integration_response.this_cors
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}
