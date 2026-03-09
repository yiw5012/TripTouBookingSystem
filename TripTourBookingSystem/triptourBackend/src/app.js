import express from "express";
import cors from "cors";
import {router as index} from "../controller/index.js";  
import {router as checkUser} from "../controller/user/checkUser.js";   
import {router as register} from "../controller/user/register.js"; 
import { router as addtour } from "../controller/tour/addtour.js"; 
import { router as addguide } from "../controller/guide/addguide.js"; 
import {router as otp} from "../controller/user/Otp.js";  

import dotenv from 'dotenv';

dotenv.config();
export const app = express();

app.use(cors());
app.use(express.json());

//app.use("/api", require("./routes/api"));
app.use(express.json());
app.use("/", index);
app.use("/checkuser", checkUser);
app.use("/register", register);
app.use("/otp" , otp)
app.use("/add-tour", addtour);
app.use("/add-guide", addguide);

app.use((req, res) => {
    res.status(404).json({ error: "Not found" });
});
