variable "subscription_id" {
    type = string
    description = "Subscription ID for the environment"
}

variable "environment" {
    type = string
    description = "The name of the environment"
    validation {
      condition = contains(["tst", "prd"], var.environment)
      error_message = "The environment must be tst or prd"
    }
}

variable "resourcegroup_prefix" {
    type = string
    description = "The default prefix for the resource groups"
}

variable "location" {
    type = string
    description = "The location for the resources"
}

variable "identity_aca" {
    type = string
    description = "Base name for the identity container app"
}