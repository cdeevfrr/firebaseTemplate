import * as admin from "firebase-admin";

// Initialize the app without config (it uses the service account automatically)
admin.initializeApp({});

const db = admin.firestore();
db.settings({ 
    databaseId: 'default-database', // this db name is created in our terraform.
}); 

const auth = admin.auth();

export { db, auth };