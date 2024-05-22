provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

module "apigateway" {
  source = "../"

  account_id       = data.aws_caller_identity.current.account_id
  region           = data.aws_region.current.name
  resources_prefix = "example" # Opcional

  api_gtw = {
    name  = "my-gateway"
    stage = "dev"
    # path  = "/example" # Opcional, padrão => "{proxy+}"

    # cognito_authorizer = { # Opcional
    #   name          = "my-cognito-authorizer"
    #   provider_arns = ["arn:aws:cognito-idp:us-east-1:000000000000:userpool/us-east-1_FAKEID"]
    # }

    integration = {
      lambdas = [ # Opcional
        {
          name = "my-lambda",
          # integration_methods = [ # Opcional, padrão => [{ method = "ANY", with_autorizer = false }]
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

      # sns = [ # Opcional
      #   {
      #     name = "my-topic"
      #     fifo = true # Opcional, padrão => false
      #     integration_methods = [ # Opcional, padrão => [{ method = "ANY", with_autorizer = false }]
      #       {
      #         method         = "GET"
      #         with_autorizer = false
      #       },
      #       {
      #         method         = "POST"
      #         with_autorizer = true
      #       }
      #     ]
      #   }
      # ]
    }
  }
}
