import { User } from "firebase/auth";
import { hitBackend } from "../APIs/Backend";


export function LandingPage({
    user,
    signOutUser
}: {
    user: User,
    signOutUser: () => void
}){
    return <div>
        <h1>Test button</h1>
        <p>This button pings the backend, which then writes a last updated time to the database, scoped to your user IDs private data.</p>
        <button onClick={() => {
            hitBackend()
        }}>
            Ping Database
        </button>
        <p>You can go to the database in the google cloud console or the firebase console and see the new collection and its contents.</p>
    </div>
}