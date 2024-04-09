# ----------------------- SNS Role -----------------------
resource "aws_iam_role" "this_sns_integration_role" {
  for_each = local.gateways

  name = "${each.value.name}__sns_integration_role"

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

# ----------------------- Policy Attachment (Module) -----------------------
module "policies" {
  source = "github.com/Coaktion/terraform-policies-module"

  region     = var.region
  account_id = var.account_id

  policies = flatten([
    for sns_policy in local.sns_integrations : {
      iam_reference = aws_iam_role.this_sns_integration_role[sns_policy.gtw_name].name
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
