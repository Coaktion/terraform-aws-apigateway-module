# ----------------------- CORS -----------------------
resource "aws_api_gateway_method" "this_cors" {
  for_each = local.gateways

  rest_api_id   = aws_api_gateway_rest_api.this[each.key].id
  resource_id   = aws_api_gateway_resource.this[each.key].id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "this_cors" {
  for_each = local.gateways

  rest_api_id = aws_api_gateway_rest_api.this[each.key].id
  resource_id = aws_api_gateway_resource.this[each.key].id
  http_method = aws_api_gateway_method.this_cors[each.key].http_method
  type        = "MOCK"
}

# ----------------------- Lambda -----------------------
resource "aws_api_gateway_method" "this_lambda" {
  for_each = local.lambda_integrations

  rest_api_id   = each.value.rest_api_id
  resource_id   = each.value.resource_id
  http_method   = each.value.method
  authorization = var.cognito_authorizer != null ? "COGNITO_USER_POOLS" : "NONE"
}

resource "aws_api_gateway_integration" "this_lambda" {
  for_each = local.lambda_integrations

  rest_api_id             = each.value.rest_api_id
  resource_id             = each.value.resource_id
  http_method             = aws_api_gateway_method.this_lambda[each.key].http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = each.value.lambda_uri
}

# ----------------------- SNS -----------------------
resource "aws_api_gateway_method" "this_pub_sub" {
  for_each = local.sns_integrations

  rest_api_id   = each.value.rest_api_id
  resource_id   = each.value.resource_id
  http_method   = each.value.method
  authorization = var.cognito_authorizer != null ? "COGNITO_USER_POOLS" : "NONE"
}

resource "aws_api_gateway_integration" "this_pub_sub" {
  for_each = local.sns_integrations

  rest_api_id = each.value.rest_api_id
  resource_id = each.value.resource_id
  http_method = aws_api_gateway_method.this_pub_sub[each.key].http_method

  integration_http_method = "POST"

  type        = "AWS"
  uri         = "arn:aws:apigateway:us-east-1:sns:action/Publish"
  credentials = aws_iam_role.this_sns_integration_role[each.value.gtw_name].arn

  passthrough_behavior = "WHEN_NO_TEMPLATES"

  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }

  request_templates = {
    "application/json" = each.value.request_mapping
  }
}
