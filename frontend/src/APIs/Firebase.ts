import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";


// Your Firebase Configuration (Found in Firebase Console, not GCP console; Project Settings)
const firebaseConfig = {
  apiKey: "AIzaSyAvQPXVuDgygvLmWL4BvA_5JFTI7Di8SY4",
  authDomain: "cdeevfrrgames.firebaseapp.com",
  projectId: "cdeevfrrgames",
  storageBucket: "cdeevfrrgames.firebasestorage.app",
  messagingSenderId: "688273328565",
  appId: "1:688273328565:web:b82d769c202f21a045f1fc"
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