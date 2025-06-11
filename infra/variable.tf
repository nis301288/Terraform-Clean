variable "project_name" {
  description = "Terraform project"
  type        = string
  default     = "TerraformApp"
}

variable "resource_group_name" {
  description = "Resource Group Name"
  type        = string
  default     = "my-TerraformApp-rg"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "subscription_id" {
    description = "Azure subscription ID"
    type        = string
  
}

variable "tenant_id" {
    description = "Azure tenant ID"
    type        = string
  
}