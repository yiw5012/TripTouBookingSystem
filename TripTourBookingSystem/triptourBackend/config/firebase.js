import admin from  "firebase-admin";
import { createRequire } from "module";

const require = createRequire(import.meta.url);
const serviceAccount = require("./firebase-admin-key.json");
if (admin.apps.length === 0) {
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        databaseURL:
      "https://triptourbookingsystem-5f7d7-default-rtdb.asia-southeast1.firebasedatabase.app",
    });
}

export default admin;
