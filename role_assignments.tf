# Role Assignments Examples
# This file demonstrates various ways to assign Entra ID roles and Azure RBAC roles
# to service principals created by this module

# Uncomment and modify these examples based on your requirements

# Example 1: Assign Entra ID Directory Role to a Service Principal
# Common roles: "Directory Readers", "Directory Writers", "Application Administrator"
#
# resource "azuread_directory_role" "dir_reader" {
#   display_name = "Directory Readers"
# }
#
# resource "azuread_directory_role_assignment" "example" {
#   role_id             = azuread_directory_role.dir_reader.template_id
#   principal_object_id = module.web_api_example.service_principal_id
# }

# Example 2: Assign Azure RBAC Role to a Service Principal
# This grants the service principal access to Azure resources
#
# data "azurerm_subscription" "current" {}
#
# resource "azurerm_role_assignment" "reader" {
#   scope                = data.azurerm_subscription.current.id
#   role_definition_name = "Reader"
#   principal_id         = module.daemon_service.service_principal_id
# }

# Example 3: Assign Service Principal to a Specific Resource Group
#
# data "azurerm_resource_group" "example" {
#   name = "my-resource-group"
# }
#
# resource "azurerm_role_assignment" "rg_contributor" {
#   scope                = data.azurerm_resource_group.example.id
#   role_definition_name = "Contributor"
#   principal_id         = module.daemon_service.service_principal_id
# }

# Example 4: Assign Service Principal to Key Vault Access
#
# data "azurerm_key_vault" "example" {
#   name                = "my-key-vault"
#   resource_group_name = "my-resource-group"
# }
#
# resource "azurerm_key_vault_access_policy" "example" {
#   key_vault_id = data.azurerm_key_vault.example.id
#   tenant_id    = local.tenant_id
#   object_id    = module.daemon_service.service_principal_id
#
#   secret_permissions = [
#     "Get",
#     "List"
#   ]
#
#   certificate_permissions = [
#     "Get",
#     "List"
#   ]
# }

# Example 5: Grant App Role from Another Application
# This allows your service principal to call another API with specific app roles
#
# data "azuread_application" "target_api" {
#   display_name = "Target API Application"
# }
#
# data "azuread_service_principal" "target_api_sp" {
#   client_id = data.azuread_application.target_api.client_id
# }
#
# resource "azuread_app_role_assignment" "example" {
#   app_role_id         = "some-app-role-id-from-target-api"
#   principal_object_id = module.daemon_service.service_principal_id
#   resource_object_id  = data.azuread_service_principal.target_api_sp.object_id
# }

# Example 6: Assign Multiple RBAC Roles Using for_each
#
# locals {
#   azure_roles = {
#     "subscription_reader" = {
#       scope = data.azurerm_subscription.current.id
#       role  = "Reader"
#       sp_id = module.web_api_example.service_principal_id
#     }
#     "storage_contributor" = {
#       scope = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/my-rg/providers/Microsoft.Storage/storageAccounts/mystorageacct"
#       role  = "Storage Blob Data Contributor"
#       sp_id = module.daemon_service.service_principal_id
#     }
#   }
# }
#
# resource "azurerm_role_assignment" "multiple" {
#   for_each             = local.azure_roles
#   scope                = each.value.scope
#   role_definition_name = each.value.role
#   principal_id         = each.value.sp_id
# }

# Example 7: Conditional Role Assignment Based on Environment
#
# resource "azurerm_role_assignment" "prod_only" {
#   count                = var.environment == "prod" ? 1 : 0
#   scope                = data.azurerm_subscription.current.id
#   role_definition_name = "Contributor"
#   principal_id         = module.daemon_service.service_principal_id
# }
