import admin from  "firebase-admin";
import { createRequire } from "module";

const require = createRequire(import.meta.url);
const serviceAccount = require("../triptourbookingsystem-5f7d7-firebase-adminsdk-fbsvc-9dcffd80fa.json");
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

export default admin;
