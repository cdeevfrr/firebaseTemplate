# Template

To use the template:

- Copy the code to your repo (probably clone or fork.)
- Fix the display name in the infrastructure/main.tf Firebase Web App instance


## To actually deploy

Make sure you have terraform & gcloud installed, you can check with

- `terraform version`
- `gcloud version`

(and init gcloud if it's your first time, `gcloud init`)

Give terraform permission to edit this project (opens a browser)
- `gcloud auth application-default login`

Update the `infrastructure/terraform.tfvars` file for your project ID.

To deploy the first time:
- `cd infrastructure`
- `terraform init`
- `terraform plan`
- `terraform apply`

To deploy in general, just that last one.


## Usage notes
- It comes with a firestore document database, which is scoped to each user. cloud functions (the backend) can access any document in the database, and users (client side) can access any document following the path `/databases/{database}/documents/users/{userId}/{x=**}` (path matching definition [here](https://firebase.google.com/docs/rules/rules-language) )
- It comes with a scheduled function that runs every minute. Starts out paused in the terraform file. 