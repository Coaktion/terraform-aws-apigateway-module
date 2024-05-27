locals {
  #########################################
  # ------------ API Gateway ------------ #
  #########################################
  gateway_name = var.resources_prefix != null ? "${var.resources_prefix}__${var.api_gtw.name}" : var.api_gtw.name

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
    )
  })

  #################################
  # ------------ SNS ------------ #
  #################################
  # sns_list = var.api_gtw.integration.sns != null ? flatten([
  #   for sns_integration in var.api_gtw.integration.sns : merge(
  #     sns_integration, { name = var.resources_prefix != null ? "${var.resources_prefix}__${sns_integration.name}" : sns_integration.name }
  #   ) if sns_integration != null
  # ]) : []
  sns_list = []

  sns_names               = flatten([for sns in local.sns_list : sns.name])
  sns_integration_methods = flatten([for sns in local.sns_list : sns.integration_methods])

  request_parse = tomap({
    for sns in local.sns_list : sns.name => "Action=Publish&TopicArn=$util.urlEncode('${data.aws_sns_topic.this[sns.name].arn}')&Message=$util.urlEncode($input.body)"
  })
  request_mapping = tomap({
    for sns in local.sns_list : sns.name => sns.fifo ? "${local.request_parse[sns.name]}&MessageGroupId=$context.requestId" : local.request_parse[sns.name]
  })

  sns_integrations = merge(
    flatten([
      for integration_method in local.sns_integration_methods : tomap({
        for sns in local.sns_list : "${upper(integration_method.method)} ${sns.name}" => {
          integration_name = "${sns.name}__${integration_method.method}"
          gtw_name         = local.gateway_name
          method           = integration_method.method
          with_autorizer   = integration_method.with_autorizer
          fifo             = sns.fifo
          topic_arn        = data.aws_sns_topic.this[sns.name].arn
          request_mapping  = local.request_mapping[sns.name]
        }
      })
    ])...
  )

  #######################################
  # ------------ Resources ------------ #
  #######################################
  # Used to redeploy API Gateway
  lambda_resources = tomap({
    # for resource in local.lambda_integrations : [
    #   aws_api_gateway_method.this_lambda[resource.method],
    #   aws_api_gateway_integration.this_lambda[resource.integration_name]
    # ]
  })
}
