# dhsc-alpha-infrastructure
Infrastructure Repository for the DHSC Alpha Delivery

# Terraform commands
```
terraform init -backend-config="dev.azurerm.tfbackend"
terraform plan -out="main.tfout"
terraform apply main.tfout
```