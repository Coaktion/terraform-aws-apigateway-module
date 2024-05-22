output "rest_api" {
  value = aws_api_gateway_rest_api.this
}

output "gtw_deploy" {
  value = aws_api_gateway_deployment.this_gtw_deployment
}
