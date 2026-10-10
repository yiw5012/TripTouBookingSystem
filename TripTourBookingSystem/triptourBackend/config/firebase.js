import admin from  "firebase-admin";
import { createRequire } from "module";
import 'dotenv/config';

const require = createRequire(import.meta.url);
const serviceAccount = require("./firebase-admin-key.json");
if (admin.apps.length === 0) {
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        databaseURL: process.env.FIREBASE_DATABASE_URL,
    });
}

export default admin;
