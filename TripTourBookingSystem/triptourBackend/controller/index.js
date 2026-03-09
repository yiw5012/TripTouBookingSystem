import express from "express";
import {conn} from "../config/db.js";
export const router = express.Router();
router.get("/", async (req, res) => {
   const [rows] = await conn.query("SELECT *FROM Member");
   res.send(rows);
});
