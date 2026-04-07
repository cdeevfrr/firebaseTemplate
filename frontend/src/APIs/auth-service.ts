import { auth } from "./Firebase";
import { GoogleAuthProvider, signInWithPopup, signOut } from 'firebase/auth';

const provider = new GoogleAuthProvider();

export const signInWithGoogle = async () => {
  try {
    await signInWithPopup(auth, provider);
  } catch (error) {
    console.error("Login failed:", error);
  }
};

export const signOutUser = () => signOut(auth);