import cors from "cors";
import express from "express";
import {router as index} from "../controller/index.js";  
import {router as checkUser} from "../controller/user/checkUser.js";   
import {router as register} from "../controller/user/register.js"; 
import { router as addtour } from "../controller/tour/addtour.js"; 
import { router as addguide } from "../controller/guide/addguide.js"; 
import {router as otp} from "../controller/user/Otp.js";  
import { router as tourAll } from "../controller/tour/tourAll.js"; 
import { router as upload } from "../controller/user/uploadCloud.js";
import {router as country} from "../controller/country/country.js"
import {router as getUser} from "../controller/user/getUser.js";
import {router as roundTour} from "../controller/tour/roundTour/roundTour.js"
import {router as booking} from "../controller/booking/booking.js";
import { router as reviewRouter } from "../controller/review/review.js";
import {router as dashboardRouter} from "../controller/dashboard/dashboard-api.js"
import { router as manageTour} from "../controller/tour/manageTour.js";
import { router as manageRound } from "../controller/tour/manageRound.js";
import dotenv from 'dotenv';
import { Server } from 'socket.io';
dotenv.config();
export const app = express();
app.use(cors());

app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));
app.use("/", index);
app.use("/checkuser", checkUser);
app.use("/register", register);
app.use("/otp" , otp)
app.use("/add-tour", addtour);
app.use("/add-guide", addguide);
app.use("/country",country)
app.use("/tourAll", tourAll);
app.use("/uploads", upload); // Serve uploaded files from the 'uploads' directory
app.use("/member", getUser);
app.use("/roundTour", roundTour);
app.use("/api/booking", booking);
app.use("/review", reviewRouter);
app.use("/dashboard", dashboardRouter);
app.use("/manage-tour", manageTour);
app.use("/manage-round", manageRound);

app.use((req, res) => {

    res.status(404).json({ error: "Not found" });
});
