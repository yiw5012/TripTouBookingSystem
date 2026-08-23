import { v2 as cloudinary } from 'cloudinary';
import { CloudinaryStorage } from 'multer-storage-cloudinary';
import multer from 'multer';

// คอนฟิก Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
});


// กำหนดการจัดเก็บไฟล์บน Cloudinary
const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'triptour_uploads', // ชื่อโฟลเดอร์ที่จะเก็บรูปบน Cloud
    allowed_formats: ['jpg', 'jpeg', 'png', 'webp']
  }
});

export const upload = multer({ storage });