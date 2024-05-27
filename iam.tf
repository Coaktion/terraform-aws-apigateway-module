####################################
# ------------ Lambda ------------ #
####################################
resource "aws_lambda_permission" "this" {
  for_each = toset(local.lambdas_name)

  statement_id  = "ExecutionFor__${each.value}"
  action        = "lambda:InvokeFunction"
  function_name = each.value
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.this.execution_arn}/*"
}

######################################
# ------------ SNS Role ------------ #
######################################
resource "aws_iam_role" "this_sns_integration_role" {
  for_each = length(local.sns_list) > 0 ? toset([local.gateway_name]) : toset([])

  name = "${each.value}__sns_role"

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

########################################################
# ------------ Policy Attachment (Module) ------------ #
########################################################
module "policies" {
  for_each = length(local.sns_list) > 0 ? toset([local.gateway_name]) : toset([])

  source = "github.com/Coaktion/terraform-policies-module"

  region     = var.region
  account_id = var.account_id

  policies = flatten([
    for sns_policy in local.sns_list : {
      iam_reference = aws_iam_role.this_sns_integration_role[each.value].name
      iam_type      = "role"
      statements = [
        {
          actions   = ["sns:Publish"]
          resources = [sns_policy.arn]
        }
      ]
    }
  ])
}
