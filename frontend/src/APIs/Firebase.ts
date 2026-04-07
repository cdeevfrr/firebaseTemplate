import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";


// Your Firebase Configuration (Found in Firebase Console, not GCP console; Project Settings)
const firebaseConfig = {
  apiKey: "FIND THIS WHOLE OBJECT IN THE FIREBASE CONSOLE (not GCP console)",
  authDomain: "FIND THIS WHOLE OBJECT IN THE FIREBASE CONSOLE (not GCP console)",
  projectId: "FIND THIS WHOLE OBJECT IN THE FIREBASE CONSOLE (not GCP console)",
  storageBucket: "FIND THIS WHOLE OBJECT IN THE FIREBASE CONSOLE (not GCP console)",
  messagingSenderId: "FIND THIS WHOLE OBJECT IN THE FIREBASE CONSOLE (not GCP console)",
  appId: "FIND THIS WHOLE OBJECT IN THE FIREBASE CONSOLE (not GCP console)"
};

// Initialize Firebase Services
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app, "default-database"); // DB name is made in our terraform.

export {
    app,
    auth,
    db,
}