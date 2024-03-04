# -------------------------- gateway --------------------------
resource "aws_api_gateway_rest_api" "this_gtw_rest_api" {
  name = "TODO"
}

resource "aws_api_gateway_resource" "this_gtw_resource" {
  parent_id = "TODO"
  path_part = "TODO"
  rest_api_id = "TODO"
}

resource "aws_api_gateway_authorizer" "this_gtw_authorizer" {
  name = "TODO"
  rest_api_id = "TODO"
}

resource "aws_api_gateway_method" "this_gtw_method" {
  rest_api_id = "TODO"
  resource_id = "TODO"
  http_method = "TODO"
  authorization = "TODO"
}

resource "aws_api_gateway_method" "this_gtw_cors_method" {
  rest_api_id = "TODO"
  resource_id = "TODO"
  http_method = "TODO"
  authorization = "TODO"
}

resource "aws_api_gateway_integration" "this_gtw_integration" {
  rest_api_id = "TODO"
  resource_id = "TODO"
  http_method = "TODO"
  type = "TODO"
}

resource "aws_api_gateway_integration" "this_gtw_cors_integration" {
  rest_api_id = "TODO"
  resource_id = "TODO"
  http_method = "TODO"
  type = "TODO"
}

resource "aws_api_gateway_method_settings" "this_gtw_method_settings" {
  rest_api_id = "TODO"
  stage_name = "TODO"
  method_path = "TODO"
  settings {}
}

resource "aws_api_gateway_deployment" "this_gtw_deployment" {
  rest_api_id = "TODO"
}
