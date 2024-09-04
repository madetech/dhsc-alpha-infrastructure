variable "environment" {}
variable "resource_prefix" {}
variable "resource_group_name" {}
variable "workspace_url" {}
variable "storage_account_name" {}
variable "string_value" {}

terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "1.38.0"
    }
  }
}

provider "azurerm" {
  skip_provider_registration = true
  features {
  }
}


provider "databricks" {
  host = var.workspace_url
}

data "databricks_spark_version" "latest_lts" {
  long_term_support = true

  depends_on = [
    var.workspace_url
  ]
}

resource "databricks_secret_scope" "dbx_secret_scope" {
  name = "infrascope"
}

resource "databricks_secret" "dbx_secret_datalake" {
  scope        = databricks_secret_scope.dbx_secret_scope.name
  key          = "datalake_access_key"
  string_value = var.string_value
}

resource "databricks_cluster" "dbx_cluster" {
  cluster_name            = "${var.resource_prefix}dbx-cluster${var.environment}"
  spark_version           = data.databricks_spark_version.latest_lts.id #
  node_type_id            = "Standard_DS3_v2"
  driver_node_type_id     = "Standard_DS3_v2"
  enable_elastic_disk     = true
  autotermination_minutes = 10
  autoscale {
    min_workers = 1
    max_workers = 2
  }
  depends_on = [databricks_secret.dbx_secret_datalake]
  spark_conf = {
    format("%s.%s.%s", "fs.azure.account.key", var.storage_account_name, "dfs.core.windows.net") = "{{secrets/infrascope/datalake_access_key}}"
  }
  spark_env_vars = {
    "ENV" = var.environment
  }
}
