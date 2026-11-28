
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


variable "frontend_ssh_public_key" {
  description = "Frontend VM SSH public key"
  type        = string
}


