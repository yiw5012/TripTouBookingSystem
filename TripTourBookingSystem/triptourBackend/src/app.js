import express from "express";
import {router as index} from "../controller/index.js";  
import {router as checkUser} from "../controller/checkUser.js";   
import {router as register} from "../controller/register.js";  
import dotenv from 'dotenv';
dotenv.config();
export const app = express();

//app.use("/api", require("./routes/api"));
app.use("/", index);
app.use("/checkuser", checkUser);
app.use("/register", register);
app.use((req, res) => {
    res.status(404).json({ error: "Not found" });
});
