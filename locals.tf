locals {
  gateways = tomap({ for api in var.api_gtw : api.name => api })

  # -------------------- Lambda --------------------
  lambdas = flatten([
    for lambda_integration in flatten([
      for gtw in var.api_gtw : gtw.integration.lambdas if gtw.integration.lambdas != null
    ])
    : lambda_integration
  ])

  lambdas_name    = flatten([for lambda in local.lambdas : lambda.name])
  lambdas_methods = flatten([for lambda in local.lambdas : lambda.methods])

  lambda_integrations = merge(
    flatten([
      for method in local.lambdas_methods : flatten([
        for lambda in local.lambdas : tomap({
          for gtw in local.gateways : "${lambda.name}__${method}" => {
            integration_name = "${lambda.name}__${method}",
            method           = method,
            lambda_uri       = data.aws_lambda_function.this[lambda.name].invoke_arn
            rest_api_id      = aws_api_gateway_rest_api.this[gtw.name].id,
            resource_id      = aws_api_gateway_resource.this[gtw.name].id
          }
        })
      ])
    ])...
  )

  # -------------------- SNS --------------------

  # -------------------- Resources --------------------
  # Used to redeploy API Gateway
  lambda_resources = toset([
    for resource in local.lambda_integrations : [
      aws_api_gateway_method.this_lambda[resource.integration_name],
      aws_api_gateway_integration.this_lambda[resource.integration_name]
    ]
  ])
}
