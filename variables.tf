variable "region" {
  description = "AWS region where the resources will be created."
  type        = string
}

variable "account_id" {
  description = "AWS account id where the resources will be created."
  type        = string
}

variable "resources_prefix" {
  description = "Prefix to be used in the resources names."
  type        = string
  nullable    = true
  default     = null
}

variable "api_gtw" {
  description = "API Gateway configuration. This is a list of objects, each object represents a gateway. Each gateway has a list of integrations and settings."

  type = object({
    name   = string
    path   = optional(string, "{proxy+}")
    stages = list(string)

    cognito_authorizer = optional(object({
      name          = string
      provider_arns = list(string)
    }))

    integration = object({
      lambdas = optional(list(object({
        name               = string                # Recover an existing lambda by name
        with_stage_postfix = optional(bool, false) # Add the stage name as a postfix to the lambda name (e.g. my-lambda__dev)

        integration_methods = optional(list(object({
          method         = string
          with_autorizer = optional(bool, false)
        })), [{ method = "ANY", with_autorizer = false }])
      })))

      sns = optional(list(object({
        name               = string # Recover an existing sns by name
        fifo               = optional(bool, false)
        with_stage_postfix = optional(bool, false) # Add the stage name as a postfix to the sns name (e.g. my-sns__dev, my-sns__dev.fifo)

        integration_methods = optional(list(object({
          method         = string
          with_autorizer = optional(bool, false)
        })), [{ method = "ANY", with_autorizer = false }])
      })))
    })

    settings = optional(object({
      metrics_enabled                            = optional(bool)
      logging_level                              = optional(string)
      data_trace_enabled                         = optional(bool)
      throttling_burst_limit                     = optional(number)
      throttling_rate_limit                      = optional(number)
      caching_enabled                            = optional(bool)
      cache_ttl_in_seconds                       = optional(number)
      cache_data_encrypted                       = optional(bool)
      require_authorization_for_cache_control    = optional(bool)
      unauthorized_cache_control_header_strategy = optional(string)
    }), {})
  })
}
