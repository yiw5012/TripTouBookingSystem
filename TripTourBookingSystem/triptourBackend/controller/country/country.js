import express from "express";
import {conn} from "../../config/db.js";

export const router = express.Router()

router.get("/",async (req,res)=>{
    try {
        const [countryRow] = await conn.query('select * from country');
        return res.json(countryRow);
    } catch (error) {
return res.status(500).json({ 
            status: 'error', 
            message: error.message, 
            sqlMessage: error.sqlMessage 
        });    }
    
    
    
})
