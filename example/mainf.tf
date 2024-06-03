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

    # cognito_authorizer = { # Opcional
    #   name          = "my-cognito-authorizer"
    #   provider_arns = ["arn:aws:cognito-idp:us-east-1:000000000000:userpool/us-east-1_FAKEID"]
    # }
  }

  integrations = {
    # "METHOD /PATH" = {...}
    "ANY {proxy+}" = { # Necessário passar "name" ou "invoke_arn"
      name = "my-function"
      # arn  = "arn:aws:lambda:us-east-1:000000000000:function:my-function"
      type           = "lambda" # "lambda" ou "sns"
      with_prefix    = false    # Opcional, padrão => true
      with_autorizer = true     # Opcional, padrão => false
    }

    # "METHOD /PATH" = {...}
    "GET path-to-topic" = { # Necessário passar "name" ou "arn"
      # name = "my-topic"
      arn            = "arn:aws:sns:us-east-1:000000000000:my-topic"
      type           = "sns"
      with_autorizer = true # Opcional, padrão => false
      # fifo = true # Opcional, padrão => false
    }
  }
}
