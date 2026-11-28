
variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  sensitive   = true
}

variable "location" {
  description = "Azure deployment region"
  type        = string
  default     = "southindia"
}

variable "resource_group_name" {
  description = "Terraform training resource group"
  type        = string
  default     = "rg-terraform-training"
}


