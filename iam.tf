######################################
# ------------ SNS Role ------------ #
######################################
resource "aws_iam_role" "this_integration_role" {
  name = "${local.gateway_name}__sns_role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "apigateway.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

  lifecycle {
    ignore_changes = [tags]
  }
}

####################################
# ------------ Lambda ------------ #
####################################
resource "aws_lambda_permission" "this" {
  for_each = local.lambda_integrations

  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.this.execution_arn}/*"
}

########################################################
# ------------ Policy Attachment (Module) ------------ #
########################################################
module "policies" {
  source = "github.com/Coaktion/terraform-policies-module"

  region     = var.region
  account_id = var.account_id

  policies = flatten([
    for sns_policy in local.sns_integrations : {
      iam_reference = aws_iam_role.this_integration_role.name
      iam_type      = "role"
      statements = [
        {
          actions   = ["sns:Publish"]
          resources = [sns_policy.topic_arn]
        }
      ]
    }
  ])
}
