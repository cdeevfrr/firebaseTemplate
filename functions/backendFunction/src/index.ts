import * as ff from '@google-cloud/functions-framework';
import { db, auth } from './firestore'

export const handleUserRequest: ff.HttpFunction = async (req, res) => {
  const allowedOrigins = [
    // ADD YOUR ORIGIN HERE
    'http://localhost:3000', // Common React port
    'http://localhost:5173', // Common Vite port
    'http://localhost:8080'  // Common Firebase emulator port
  ];

  const origin = req.headers.origin as string;

  // If the origin is in our whitelist, allow it
  if (allowedOrigins.includes(origin)) {
    res.set('Access-Control-Allow-Origin', origin);
  }

  if (req.method === 'OPTIONS') {
    res.set('Access-Control-Allow-Methods', 'GET, POST');
    res.set('Access-Control-Allow-Headers', 'Authorization, Content-Type');
    res.status(204).send('');
    return;
  }

  try {
    // FIRST Verify Firebase Auth Token
    // If not authenticated, kick them out.
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith('Bearer ')) {
      res.status(401).send('Unauthorized: No token provided');
      return;
    }
    // Now that they have a token, all data access is under their uid, so 
    // they're trustworthy.

    const idToken = authHeader.split('Bearer ')[1];
    // this next line throws FirebaseAuthError if not valid.
    const decodedToken = await auth.verifyIdToken(idToken);
    const uid = decodedToken.uid;

    await db.collection('users').doc(uid)
      .set({lastUpdated: Date.now()})
    
    return res.status(200).json({'message': `Successfully updated last touch from user.`})
  } catch (error){
    return res.status(500).send('Internal server error');
  }
};