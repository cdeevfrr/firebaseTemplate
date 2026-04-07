import React, { useEffect, useState } from 'react';
import { onAuthStateChanged, User } from 'firebase/auth';
import { auth } from './APIs/Firebase';
import { signInWithGoogle, signOutUser } from './APIs/auth-service';
import { LandingPage } from './Components/landingPage';


export function App() {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // This listener detects if a user is already logged in from a previous session
    const unsubscribe = onAuthStateChanged(auth, (currentUser) => {
      setUser(currentUser);
      setLoading(false);
    });
    return () => unsubscribe();
  }, []);

  if (loading) return <div style={{ padding: '20px' }}>Checking authentication...</div>;

  if (!user) {
    return (
      <div style={{ textAlign: 'center', marginTop: '50px', padding: '20px', fontFamily: 'sans-serif' }}>
        <h1>Firebase Template</h1>
        <button 
            onClick={signInWithGoogle}
            style={{ padding: '10px 20px', backgroundColor: '#4f46e5', color: 'white', border: 'none', borderRadius: '6px', cursor: 'pointer' }}
        >
            Sign in with Google
        </button>
      </div>
    );
  }

  return <LandingPage user={user} signOutUser={signOutUser}/>
}

const styles: Record<string, React.CSSProperties> = {
  pageWrapper: {
    margin: 0,
    minHeight: '100vh',
  }
};

export default App;
