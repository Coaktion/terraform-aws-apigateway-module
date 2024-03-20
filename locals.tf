locals {
  gateways = tomap({ for api in var.api_gtw : api.name => api })
  authorizers = tomap({
    for gtw in var.api_gtw : gtw.name => gtw.cognito_authorizer if gtw.cognito_authorizer != null
  })

  # -------------------- Lambda --------------------
  lambdas = flatten([
    for lambda_integration in flatten([
      for gtw in var.api_gtw : gtw.integration.lambdas if gtw.integration.lambdas != null
    ])
    : lambda_integration
  ])

  lambdas_name                = flatten([for lambda in local.lambdas : lambda.name])
  lambdas_integration_methods = flatten([for lambda in local.lambdas : lambda.integration_methods])

  lambda_integrations = merge(
    flatten([
      for integration_method in local.lambdas_integration_methods : flatten([
        for lambda in local.lambdas : tomap({
          for gtw in local.gateways : "${lambda.name}__${integration_method.method}" => {
            integration_name = "${lambda.name}__${integration_method.method}"
            gtw_name         = gtw.name
            method           = integration_method.method
            with_autorizer   = integration_method.with_autorizer
            lambda_uri       = data.aws_lambda_function.this[lambda.name].invoke_arn
            rest_api_id      = aws_api_gateway_rest_api.this[gtw.name].id
            resource_id      = aws_api_gateway_resource.this[gtw.name].id
          }
        })
      ])
    ])...
  )

  # -------------------- SNS --------------------
  sns_list = flatten([
    for sns_integration in flatten([
      for gtw in var.api_gtw : gtw.integration.sns if gtw.integration.sns != null
    ])
    : sns_integration
  ])

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
      for integration_method in local.sns_integration_methods : flatten([
        for sns in local.sns_list : tomap({
          for gtw in local.gateways : "${sns.name}__${integration_method.method}" => {
            integration_name = "${sns.name}__${integration_method.method}"
            gtw_name         = gtw.name
            method           = integration_method.method
            with_autorizer   = integration_method.with_autorizer
            fifo             = sns.fifo
            topic_arn        = data.aws_sns_topic.this[sns.name].arn
            rest_api_id      = aws_api_gateway_rest_api.this[gtw.name].id
            resource_id      = aws_api_gateway_resource.this[gtw.name].id
            request_mapping  = local.request_mapping[sns.name]
          }
        })
      ])
    ])...
  )

  # -------------------- Resources --------------------
  # Used to redeploy API Gateway
  lambda_resources = toset([
    for resource in local.lambda_integrations : [
      aws_api_gateway_method.this_lambda[resource.integration_name],
      aws_api_gateway_integration.this_lambda[resource.integration_name]
    ]
  ])
}
