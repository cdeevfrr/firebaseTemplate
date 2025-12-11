# Template

To use the template:

- Copy the code to your repo (probably clone or fork.)
- Fix the display name in the infrastructure/main.tf Firebase Web App instance


## To actually deploy

Make sure you have terraform installed, you can check with

- `terraform version`

Update the `infrastructure/terraform.tfvars` file for your project ID.

To deploy the first time:
- `terraform init`
- `terraform plan`
- `terraform apply`

To deploy in general, just that last one.