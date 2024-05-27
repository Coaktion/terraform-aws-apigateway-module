######################################
# ------------ REST API ------------ #
######################################
data "aws_api_gateway_rest_api" "this" {
  for_each = !var.api_gtw.create_api ? toset([local.gateway_name]) : toset([])

  name = each.value
}

####################################
# ------------ Lambda ------------ #
####################################
# Recover Lambda ARN for Lambda integration
data "aws_lambda_function" "this" {
  for_each      = toset(local.lambdas_name)
  function_name = each.value
}

#################################
# ------------ SNS ------------ #
#################################
# Recover Topic ARN for SNS integration
data "aws_sns_topic" "this" {
  for_each = toset(local.sns_names)
  name     = each.value
}
