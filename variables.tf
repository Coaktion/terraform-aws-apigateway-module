variable "api_gtw" {
  description = "API Gateway configuration. This is a list of objects, each object represents a gateway. Each gateway has a list of integrations and settings."

  type = list(object({
    name  = string
    path  = optional(string, "{proxy+}")
    stage = string

    integration = object({
      lambdas = optional(list(object({
        name    = string # Recover an existing lambda by name
        methods = optional(list(string), ["ANY"])
      })))

      sns = optional(list(object({
        name    = string # Recover an existing sns by name
        fifo    = optional(bool, false)
        methods = optional(list(string), ["ANY"])
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
  }))
}

variable "cognito_authorizer" {
  type = object({
    name          = string
    type          = string
    provider_arns = list(string)
  })
  default = null
}
