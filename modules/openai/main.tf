variable "resource_prefix" {}
variable "resource_group_name" {}
variable "location" {}
variable "environment" {}


//resource "azurerm_cognitive_deployment" "gpt_4o" {
//  name                 = "GPT-4o"
//  cognitive_account_id = azurerm_cognitive_account.openai.id
//  model {
//    format  = "OpenAI"
//    name    = "gpt-4o"
//    version = "2024-05-13"
//    sku_name = "S0"
//  }
//  scale {
//    type = standard
//  }
//
//}