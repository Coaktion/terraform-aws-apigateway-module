######################################################
# ------------ Integration Response Map ------------ #
######################################################
resource "aws_api_gateway_method_response" "this" {
  for_each = local.lambdas

  rest_api_id = local.rest_api.id
  resource_id = aws_api_gateway_resource.this[each.value.path].id
  http_method = each.value.method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  depends_on = [aws_api_gateway_method.this_lambda]
}

#######################################
# ------------ CORS Mock ------------ #
#######################################
resource "aws_api_gateway_method_response" "this_cors" {
  for_each = local.api_resources

  rest_api_id = local.rest_api.id
  resource_id = aws_api_gateway_resource.this[each.value].id
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

  depends_on = [aws_api_gateway_method.this_cors]
}

resource "aws_api_gateway_integration_response" "this_cors" {
  for_each = local.api_resources

  rest_api_id = local.rest_api.id
  resource_id = aws_api_gateway_resource.this[each.value].id
  http_method = "OPTIONS"
  status_code = "200"

  response_templates = {
    "application/json" = ""
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent,X-Amzn-Trace-Id'",
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,DELETE,GET,HEAD,PATCH,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_method_response.this_cors,
    aws_api_gateway_integration.this_cors
  ]
}
