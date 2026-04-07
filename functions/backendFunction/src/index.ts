import * as ff from '@google-cloud/functions-framework';
import { db, auth } from './firestore'

export const handleUserRequest: ff.HttpFunction = async (req, res) => {
  console.log("Here's a log! You can find me in the google cloud logs explorer.")
  // This link shows you a great way to search for these logs:
  // https://console.cloud.google.com/logs/query;query=resource.labels.service_name%3D%22backend%22

  const allowedOrigins = [
    'https://YOURAPP.web.app', // frontend
    'http://localhost:3000', // Common React port
    'http://localhost:5173', // Common Vite port
    'http://localhost:8080'  // Common Firebase emulator port
  ];

  const origin = req.headers.origin as string;

  // If the origin is in our allowlist, permit it.
  if (allowedOrigins.includes(origin)) {
    res.set('Access-Control-Allow-Origin', origin);
  }

  // Tell browsers not to cache CORS responses; it varies based on the incoming origin.
  res.set('Vary', 'Origin');

  if (req.method === 'OPTIONS') {
    res.set('Access-Control-Allow-Methods', 'GET, POST');
    res.set('Access-Control-Allow-Headers', 'Authorization, Content-Type');
    res.status(204).send('');
    return;
  }

  try {
    // FIRST Verify Firebase Auth Token
    // If not authenticated, kick them out.
    // These requests can come from anyone on the internet, 
    // so as soon as CORS is done, we need to do this check immediately.
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

    // Now that we have a user ID, we can actually do the behavior of the app.
    await db.collection('users').doc(uid)
      .set({lastUpdated: Date.now()})
    
    // Once app behavior over, return a response.
    return res.status(200).json({'message': `Successfully updated last touch from user.`})
  } catch (error){
    return res.status(500).send('Internal server error');
  }
};