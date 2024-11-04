# dhsc-alpha-infrastructure
Infrastructure Repository for the DHSC Alpha Delivery

# Terraform commands
```
terraform init -backend-config="dev.azurerm.tfbackend"
terraform plan -var="subscription_id=2466c36e-08aa-4500-80a1-68f1a1492de9"
terraform apply main.tfout
```