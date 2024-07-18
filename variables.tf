# Variables - move to seperate file when too many
variable "resource_prefix" {
  description = "Prefix for all resources"
  default     = "dapalpha"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
  default     = "dev"
}
