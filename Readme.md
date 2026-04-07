# Template

Follow all the instructions below to get started using this template! They have to be followed in order, particularly backend needs to exist to get the frontend up and working.


## Initial steps

- Make a GCP project
- Copy the code to your repo (probably clone or fork.)
- Fix the display name in the infrastructure/main.tf Firebase Web App instance
- Update the project ID in the .tfvars file
- (Once per google account) Start making a firebase project, accept terms of service, and then abort making the project.

Now, we can deploy the backend.

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

Find the frontend's "Firebase.ts" file, and the config object there. Update it from the GCP console - you should be able to copy-paste the whole JSON object. 

In the Firebase Console (not the google cloud console) find the deployed function's URL. It shoud have `.run.app` not `.net`. Tell the frontend how to hit it in `frontend/src/APIs/Backend.ts`.

In the firebase console for your project, add Google as a new authentication provider. Lookup how to do this if you haven't done it before!

Then, `npm run build` and `npm run deploy` should work from within the frontend folder! They'll tell you the URL to visit. 

Go add that URL to the backend's cors allow list, functions/backendFunction/src/index.ts. Redeploy the backend.

Now, you should be able click around the frontend UI and hit the database, and see the changes in the cloud console!


## Usage notes
- It comes with a firestore document database, which is scoped to each user. cloud functions (the backend) can access any document in the database, and users (client side) can access any document following the path `/databases/{database}/documents/users/{userId}/{x=**}` (path matching definition [here](https://firebase.google.com/docs/rules/rules-language) )
- It comes with a scheduled function that runs every minute. Starts out paused in the terraform file. 