import express from "express";
import {conn} from "../config/db.js";
export const router = express.Router();
router.get("/", async (req, res) => {
   const [rows] = await conn.query("SELECT email,password FROM Member");
   res.send(rows);
});
