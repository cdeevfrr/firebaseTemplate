# Template

To use the template:

- Copy the code to your repo (probably clone or fork.)
- Fix the display name in the infrastructure/main.tf Firebase Web App instance


## To actually deploy

There are 3 pieces: Infrasctucture, backend, and frontend.

Infrastructure & backend are deployed together via terraform.
Frontend is deployed via firebase.

### Infrastructure 

First, make yourself a google cloud project for this to live in. The terraform will create a firebase project inside it.

You have to accept the firebase Terms Of Service at least once per google account to deploy this terraform (you can start making a firebase project and abort to accept the TOS).

Now, make sure you have terraform & gcloud installed, you can check with

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

## Frontend

Make sure you have firebase CLI tools installed. You can check with 
`firebase --version`

Once per project, run `firebase use myProjectID`

Then, `npm run build` and `npm run deploy` should work from within the frontend folder!


## Usage notes
- It comes with a firestore document database, which is scoped to each user. cloud functions (the backend) can access any document in the database, and users (client side) can access any document following the path `/databases/{database}/documents/users/{userId}/{x=**}` (path matching definition [here](https://firebase.google.com/docs/rules/rules-language) )
- It comes with a scheduled function that runs every minute. Starts out paused in the terraform file. 