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

  api_gtw = [
    {
      name  = "gateway_name"
      path  = "{proxy+}"
      stage = "dev"

      cognito_authorizer = { # Optional
        name          = "my-cognito-authorizer"
        provider_arns = ["arn:aws:cognito-idp:us-east-1:000000000000:userpool/us-east-1_FAKEID"]
      }

      # All integrations should be previously created
      integration = {
        lambdas = [ # Optional
          {
            name = "my-lambda",

            # Default: [{ method = "ANY", with_autorizer = false }]
            # integration_methods = [ # Optional
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
        sns = [ # Optional
          {
            name = "my-tpoic"
            # fifo = true # Optional

            # Default: [{ method = "ANY", with_autorizer = false }]
            # integration_methods = [ # Optional
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
```
