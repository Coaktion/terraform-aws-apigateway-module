provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

module "apigateway" {
  source = "../"

  api_gtw = [
    {
      name  = "gateway_name"
      path  = "{proxy+}"
      stage = "dev"

      cognito_authorizer = { # Opcional
        name          = "my-cognito-authorizer"
        provider_arns = ["arn:aws:cognito-idp:us-east-1:000000000000:userpool/us-east-1_FAKEID"]
      }

      integration = {
        lambdas = [ # Opcional
          {
            name = "my-lambda",
            # integration_methods = [ # Opcional
            #   {
            #     method         = "GET"
            #     with_autorizer = false
            #   },
            #   {
            #     method         = "POST"
            #     with_autorizer = true
            #   }
            # ]
          }
        ]
        sns = [ # Opcional
          {
            name = "my-tpoic"
            # fifo = true # Opcional
            # integration_methods = [ # Opcional
            #   {
            #     method         = "GET"
            #     with_autorizer = false
            #   },
            #   {
            #     method         = "POST"
            #     with_autorizer = true
            #   }
            # ]
          }
        ]
      }
    }
  ]
}
