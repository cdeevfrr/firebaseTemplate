import { auth } from "./Firebase";

const BACKEND_URL = "https://backend-t73ndrz42q-uc.a.run.app";

export async function hitBackend() {
    const user = auth.currentUser;
    if (!user) throw new Error("Not authenticated");
    const idToken = await user.getIdToken();

    const response = await fetch(BACKEND_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${idToken}`
    },
  });

  if (!response.ok) {
    const err = await response.text();
    throw new Error(`Backend Error: ${err}`);
  }

  return await response.json();
}