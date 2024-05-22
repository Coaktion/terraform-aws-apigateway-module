# Terraform API Gateway

Terraform module to create N API Gateway resources with N integrations.

## Usage

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
  resources_prefix = "example" # Optional

  api_gtw = {
    name  = "my-gateway"
    stage = "dev"
    # path  = "/example" # Optional, default => "{proxy+}"

    # cognito_authorizer = { # Optional
    #   name          = "my-cognito-authorizer"
    #   provider_arns = ["arn:aws:cognito-idp:us-east-1:000000000000:userpool/us-east-1_FAKEID"]
    # }

    integration = {
      lambdas = [ # Optional
        {
          name = "my-lambda",
          # integration_methods = [ # Optional, default => [{ method = "ANY", with_autorizer = false }]
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

      # sns = [ # Optional
      #   {
      #     name = "my-topic"
      #     fifo = true # Optional, default => false
      #     integration_methods = [ # Optional, default => [{ method = "ANY", with_autorizer = false }]
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
```
