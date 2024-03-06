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

      # All integrations should be previously created
      integration = {
        lambdas = [ # Opcional
          {
            name = "my-lambda",
            # methods = ["POST", "GET", ...] # Opcional
          }
        ]
        sns = [ # Opcional
          {
            name = "my-tpoic"
            # fifo = true # Opcional
            # methods = ["POST", "GET", ...] # Opcional
          }
        ]
      }
    }
  ]
}
```
