import express from "express";
import { upload } from "../middleware/upload.js";

export const router = express.Router();

router.post('/upload', upload.fields([
  { name: 'image', maxCount: 1 },
  { name: 'passport', maxCount: 1 },
  { name: 'slip', maxCount: 1 },
  {name: 'passpot_passenger', maxCount :1 }
]), async (req, res) => {
  try {
    const imageFile = req.files?.image?.[0];
    const passportFile = req.files?.passport?.[0];
     const passpot_passenger = req.files?.passpot_passenger?.[0];
const slipFile = req.files?.slip?.[0];
    if (!imageFile && !passportFile) {
      return res.status(400).json({ success: false, error: 'No file uploaded' });
    }

    const imageUrl = imageFile?.path ?? null;
    const passportUrl = passportFile?.path ?? null;
    const slipUrl = slipFile?.path ?? null;
    const passpot_passengerUrl = passpot_passenger?.path ?? null

    console.log('Image uploaded:', imageUrl);
    console.log('Passport uploaded:', passportUrl);
    console.log('Slip uploaded:', slipUrl);
        console.log('passpot_passenger uploaded:', passpot_passengerUrl);

   return res.json({ success: true, imageUrl, passportUrl, slipUrl ,passpot_passengerUrl});
  } catch (error) {
    console.error('Error uploading file:', error);
    return res.status(500).json({ success: false, error: 'Failed to upload file' });
  }
});