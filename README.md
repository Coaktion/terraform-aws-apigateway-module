# Terraform AWS API Gateway

Módulo Terraform para criar uma AWS API Gateway com N integrações, essas que podem ser com `lambdas` ou tópicos `sns`.

## Uso

```hcl
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

    cognito_authorizer = { # Opcional
      name          = "my-cognito-authorizer"
      provider_arns = ["arn:aws:cognito-idp:us-east-1:000000000000:userpool/us-east-1_FAKEID"]
    }

    # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method_settings#settings
    settings = { # Opcional
      metrics_enabled                            = true
      logging_level                              = "INFO"
      data_trace_enabled                         = true
      throttling_burst_limit                     = 1000
      throttling_rate_limit                      = 500
      caching_enabled                            = true
      cache_ttl_in_seconds                       = 3600
      cache_data_encrypted                       = true
      require_authorization_for_cache_control    = true
      unauthorized_cache_control_header_strategy = "SUCCEED_WITH_RESPONSE_HEADER"
    }
  }

  integrations = {
    # "METHOD /PATH" = {...}
    "GET /{proxy+}" = { # Necessário passar "name" ou "invoke_arn"
      name = "my-function"
      # arn  = "arn:aws:lambda:us-east-1:000000000000:function:my-function"
      type           = "lambda" # "lambda" ou "sns"
      with_prefix    = false    # Opcional, padrão => true
      with_autorizer = true     # Opcional, padrão => false
    }

    # "METHOD /PATH" = {...}
    "OPTIONS /{proxy+}" = { # A lambda do método options será responsável pelo controle de CORS da API Gateway
      # name = "my-function"
      arn            = "arn:aws:lambda:us-east-1:000000000000:function:my-function"
      type           = "lambda" # "lambda" ou "sns"
      with_prefix    = false    # Opcional, padrão => true
      with_autorizer = true     # Opcional, padrão => false
    }

    # "METHOD /PATH" = {...}
    "GET /{proxy+}" = { # Necessário passar "name" ou "invoke_arn"
      name = "my-topic"
      # arn  = "arn:aws:sns:us-east-1:000000000000:my-sns-topic"
      type           = "sns" # "lambda" ou "sns"
      with_prefix    = false # Opcional, padrão => true
      with_autorizer = true  # Opcional, padrão => false
      fifo           = true  # Opcioanl, padrão => false
    }
  }
}
```
