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
    for lambda in var.api_gtw.integration.lambdas : flatten([
      for stage in var.api_gtw.stages : merge(
        lambda, {
          name         = var.resources_prefix != null ? lambda.with_stage_postfix ? "${var.resources_prefix}__${lambda.name}__${stage}" : "${var.resources_prefix}__${lambda.name}" : lambda.with_stage_postfix ? "${lambda.name}__${stage}" : lambda.name
          service_name = lambda.name
        }
      ) if lambda != null
    ])
  ]) : []

  lambdas_name = flatten([for lambda in local.lambdas : lambda.name])

  lambda_methods = var.api_gtw.integration.lambdas != null ? merge(
    flatten([
      for lambda in var.api_gtw.integration.lambdas : tomap({
        for int_method in lambda.integration_methods : int_method.method => int_method
      })
    ])...
  ) : tomap({})

  lambda_integrations = merge(
    flatten([
      for stage in var.api_gtw.stages : flatten([
        for lambda in local.lambdas : tomap({
          for integration in lambda.integration_methods : "${upper(integration.method)} ${lambda.name}" => {
            integration_name = "${upper(integration.method)} ${lambda.name}"
            gtw_name         = local.gateway_name
            lambda_name      = lambda.name
            service_name     = lambda.service_name
            method           = integration.method
            lambda_uri       = data.aws_lambda_function.this[lambda.name].invoke_arn
          }
        })
      ])
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
    for stage in var.api_gtw.stages : stage => flatten([
      for resource in local.lambda_integrations : [
        aws_api_gateway_method.this_lambda[resource.method],
        aws_api_gateway_integration.this_lambda[resource.integration_name]
      ]
    ])
  })
}
