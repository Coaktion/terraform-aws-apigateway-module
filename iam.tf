# ----------------------- SNS -----------------------
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

resource "aws_iam_policy" "this_sns_publish_policy" {
  for_each = local.sns_integrations

  name = "${each.value.integration_name}__sns_publish_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = [
          each.value.topic_arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sns_integration_policy" {
  for_each = local.sns_integrations

  policy_arn = aws_iam_policy.this_sns_publish_policy[each.value.integration_name].arn
  role       = aws_iam_role.this_sns_integration_role[each.value.gtw_name].name
}
