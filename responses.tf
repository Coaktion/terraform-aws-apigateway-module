resource "aws_api_gateway_method_response" "this_lambda" {
  for_each = local.lambda_integrations

  rest_api_id = each.value.rest_api_id
  resource_id = each.value.resource_id
  http_method = each.value.method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  depends_on = [
    aws_api_gateway_method.this_lambda
  ]
}

# -------------------------- CORS Mock --------------------------
resource "aws_api_gateway_method_response" "this_cors" {
  for_each = local.gateways

  rest_api_id = aws_api_gateway_rest_api.this[each.key].id
  resource_id = aws_api_gateway_resource.this[each.key].id
  http_method = "OPTIONS"
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  depends_on = [
    aws_api_gateway_method.this_cors
  ]
}

resource "aws_api_gateway_integration_response" "this_cors" {
  for_each = local.gateways

  rest_api_id = aws_api_gateway_rest_api.this[each.key].id
  resource_id = aws_api_gateway_resource.this[each.key].id
  http_method = "OPTIONS"
  status_code = "200"

  response_templates = {
    "application/json" = ""
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'*'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_method_response.this_cors,
    aws_api_gateway_integration.this_cors
  ]
}
