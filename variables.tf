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
    name       = string
    stage      = string
    create_api = optional(bool, true) # If set to false, the API Gateway will be recovered by name

    cognito_authorizer = optional(object({
      name          = string
      provider_arns = list(string)
    }))

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

variable "integrations" {
  description = "List of integrations to link with the API Gateway."
  type = map(object({
    name = optional(string) # Recover an existing resource by name
    arn  = optional(string) # ARN of the resource to be integrated

    type = string                # Type of the resource to be integrated (lambda, sns)
    fifo = optional(bool, false) # If the resource is a fifo topic/queue

    with_prefix    = optional(bool, true) # Add the resources_prefix to the resource name
    with_autorizer = optional(bool, false)
  }))

  validation { # Check if the resource type is valid
    condition = alltrue([
      for key, value in var.integrations : value.type == "lambda" || value.type == "sns"
    ])
    error_message = "The resource type must be 'lambda' or 'sns'."
  }

  validation { # Check if the integration has name or arn
    condition = alltrue([
      for key, value in var.integrations : value.name != null || value.arn != null
    ])
    error_message = "The integration must have a name or an ARN."
  }
}
