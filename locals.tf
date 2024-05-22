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

  ####################################
  # ------------ Lambda ------------ #
  ####################################
  lambdas = var.api_gtw.integration.lambdas != null ? flatten([
    for lambda in var.api_gtw.integration.lambdas : merge(
      lambda, { name = var.resources_prefix != null ? "${var.resources_prefix}__${lambda.name}" : lambda.name }
    ) if lambda != null
  ]) : []

  lambdas_name                = flatten([for lambda in local.lambdas : lambda.name])
  lambdas_integration_methods = flatten([for lambda in local.lambdas : lambda.integration_methods])


  lambda_integrations = merge(
    flatten([
      for integration_method in local.lambdas_integration_methods : tomap({
        for lambda in local.lambdas : "${upper(integration_method.method)} ${lambda.name}" => {
          integration_name = "${upper(integration_method.method)} ${lambda.name}"
          gtw_name         = local.gateway_name
          lambda_name      = lambda.name
          method           = integration_method.method
          with_autorizer   = integration_method.with_autorizer
          lambda_uri       = data.aws_lambda_function.this[lambda.name].invoke_arn
          rest_api_id      = aws_api_gateway_rest_api.this.id
          resource_id      = aws_api_gateway_resource.this.id
        }
      })
    ])...
  )

  #################################
  # ------------ SNS ------------ #
  #################################
  sns_list = var.api_gtw.integration.sns != null ? flatten([
    for sns_integration in var.api_gtw.integration.sns : merge(
      sns_integration, { name = var.resources_prefix != null ? "${var.resources_prefix}__${sns_integration.name}" : sns_integration.name }
    ) if sns_integration != null
  ]) : []

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
          rest_api_id      = aws_api_gateway_rest_api.this.id
          resource_id      = aws_api_gateway_resource.this.id
          request_mapping  = local.request_mapping[sns.name]
        }
      })
    ])...
  )

  #######################################
  # ------------ Resources ------------ #
  #######################################
  # Used to redeploy API Gateway
  lambda_resources = toset([
    for resource in local.lambda_integrations : [
      aws_api_gateway_method.this_lambda[resource.integration_name],
      aws_api_gateway_integration.this_lambda[resource.integration_name]
    ]
  ])
}
