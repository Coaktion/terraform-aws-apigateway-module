output "rest_api" {
  value = local.rest_api
}

output "gtw_deploy" {
  value = aws_api_gateway_deployment.this_gtw_deployment
}
