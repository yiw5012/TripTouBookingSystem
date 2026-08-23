import express from "express";
import {conn} from "../../config/db.js"
import nodemailer from "nodemailer";
import admin from "../../config/firebase.js";

export const router = express.Router();

function generateOTP(){
 return Math.floor(100000 + Math.random() * 900000);
}


const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS
  }
});

router.post("/send-otp", async (req,res)=>{

    const email = req.body.email;
    if (!email || typeof email !== 'string' || email.trim() === '') {
      return res.status(400).json({ success:false, error:'Invalid email' });
    }

    const otp = generateOTP();

    try{
      

      // Verify user exists in member table
      const [memberRows] = await conn.query(
        "SELECT member_id FROM member WHERE email = ?",
        [email.trim()]
      );

      if (!memberRows || memberRows.length === 0) {
        return res.status(404).json({ success:false, error:'User not found' });
      }

      await conn.query(
        "UPDATE member SET otp = ?, expire_time = DATE_ADD(NOW(), INTERVAL 5 MINUTE) WHERE email = ?",
        [otp.toString(), email.trim()]
      );

      await transporter.sendMail({
        from: process.env.EMAIL_USER,
        to: email.trim(),
        subject: "OTP Reset Password",
        html: `
          <h2>Your OTP Code</h2>
          <p>Your OTP is:</p>
          <h1>${otp}</h1>
          <p>This code will expire in 5 minutes.</p>
        `
      });

      res.json({
        success:true,
        message:"OTP sent"
      });

    } catch (error) {
      console.log(error);
      return res.status(500).json({success:false,error: error.message});  
    }
});

router.post("/verify-otp", async (req, res) => {

  try {
    const { email, otp } = req.body;

    if (!email || typeof email !== 'string' || email.trim() === '' || !otp || typeof otp !== 'string') {
      return res.status(400).json({ success: false, error: 'Invalid request' });
    }

    const query = `
      SELECT member_id FROM member
      WHERE email = ? AND otp = ? AND expire_time > NOW()
    `;

    const [rows] = await conn.query(query, [email.trim(), otp.trim()]);

    if (!rows || rows.length === 0) {
      return res.json({ success: false });
    }

    res.json({ success: true });
  } catch (e) {
    console.error(e);
    res.status(500).json({ success: false, error: e.message });
  }
});

router.post("/reset-password", async (req,res)=>{

 const {email,password} = req.body;

 try{

 const user = await admin.auth().getUserByEmail(email);

 await admin.auth().updateUser(user.uid,{
   password: password
 });

 res.json({success:true});

 }catch(e){
 console.error(e);
 res.json({success:false});

 }

});
