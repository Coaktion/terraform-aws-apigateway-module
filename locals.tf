locals {
  #########################################
  # ------------ API Gateway ------------ #
  #########################################
  gateway_name = var.resources_prefix != null ? "${var.resources_prefix}__${var.api_gtw.name}" : var.api_gtw.name
  rest_api = var.api_gtw.create_api ? {
    id               = aws_api_gateway_rest_api.this.id
    root_resource_id = aws_api_gateway_rest_api.this.root_resource_id
    execution_arn    = aws_api_gateway_rest_api.this.execution_arn
    } : {
    id               = data.aws_api_gateway_rest_api.this[local.gateway_name].id
    root_resource_id = data.aws_api_gateway_rest_api.this[local.gateway_name].root_resource_id
    execution_arn    = data.aws_api_gateway_rest_api.this[local.gateway_name].execution_arn
  }

  authorizer = var.api_gtw.cognito_authorizer != null ? tomap({
    local.gateway_name = {
      name          = var.api_gtw.cognito_authorizer.name
      provider_arns = var.api_gtw.cognito_authorizer.provider_arns
    }
  }) : {}

  # var.integrations keys -> "METHOD /PATH"
  api_methods   = toset([for k, v in var.integrations : split(" ", k)[0]]) # split(" ", k)[0] -> METHOD
  api_resources = toset([for k, v in var.integrations : split(" ", k)[1]]) # split(" ", k)[1] -> PATH

  ##########################################
  # ------------ Integrations ------------ #
  ##########################################
  integrations = tomap({
    for k, integration in var.integrations : k => merge(
      integration,
      {
        name   = integration.name == null ? null : var.resources_prefix != null && integration.with_prefix ? "${var.resources_prefix}__${integration.name}" : integration.name
        method = split(" ", k)[0]
        path   = split(" ", k)[1]
      }
    )
  })

  ####################################
  # ------------ Lambda ------------ #
  ####################################
  lambdas_name = flatten([
    for integration in local.integrations : integration.name
    if integration.name != null && integration.type == "lambda"
  ])

  lambdas = tomap({
    for k, lambda in local.integrations : k => merge(
      lambda,
      { arn = lambda.arn != null ? lambda.arn : data.aws_lambda_function.this[lambda.name].invoke_arn }
    ) if lambda.type == "lambda"
  })

  #################################
  # ------------ SNS ------------ #
  #################################
  request_parse = tomap({ # Used to parse request body
    for k, integration in local.integrations : k => format(
      "Action=Publish&TopicArn=$util.urlEncode('%s')&Message=$util.urlEncode($input.body)",
      integration.arn != null ? integration.arn : data.aws_sns_topic.this[integration.name].arn
    ) if integration.type == "sns"
  })

  sns_names = flatten([
    for k, integration in local.integrations : integration.fifo ? "${integration.name}.fifo" : integration.name
    if integration.name != null && integration.type == "sns"
  ])

  sns_list = tomap({
    for k, sns in local.integrations : k => merge(
      sns,
      {
        arn             = sns.arn != null ? sns.arn : data.aws_sns_topic.this[sns.name].arn
        request_mapping = sns.fifo ? "${local.request_parse[k]}&MessageGroupId=$context.requestId" : local.request_parse[k]
      }
    ) if sns.type == "sns"
  })

  #######################################
  # ------------ Resources ------------ #
  #######################################
  lambda_resources = flatten([
    for k, integration in local.integrations : [
      aws_api_gateway_method.this_lambda[k],
      aws_api_gateway_integration.this_lambda[k]
    ] if integration.type == "lambda"
  ])

  sns_resources = flatten([
    for k, integration in local.integrations : [
      aws_api_gateway_method.this_pub_sub[k],
      aws_api_gateway_integration.this_pub_sub[k]
    ] if integration.type == "sns"
  ])

  deploy_trigger = flatten([
    for resource in local.api_resources : flatten([
      local.lambda_resources, # If any method or integration from lambda changes, the deployment will be triggered
      local.sns_resources,    # If any method or integration from sns changes, the deployment will be triggered
      aws_api_gateway_integration_response.this_cors[resource],
      aws_api_gateway_method_response.this_cors[resource],
    ])
  ])
}
