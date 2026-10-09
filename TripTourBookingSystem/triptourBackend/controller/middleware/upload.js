import { v2 as cloudinary } from 'cloudinary';
import { CloudinaryStorage } from 'multer-storage-cloudinary';
import multer from 'multer';

// ==========================================================
// CLOUDINARY CONFIG
// ==========================================================

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
});


// ==========================================================
// STORAGE เดิม
// ใช้กับ image / passport / slip / passenger
// ห้ามเปลี่ยนพฤติกรรมเดิม
// ==========================================================

const storage = new CloudinaryStorage({

  cloudinary: cloudinary,

  params: {
    folder: 'triptour_uploads',

    allowed_formats: [
      'jpg',
      'jpeg',
      'png',
      'webp'
    ]
  }

});


// ใช้ของเดิมต่อไป
export const upload = multer({
  storage
});


// ==========================================================
// TOUR STORAGE
// ใช้สำหรับ
// 1. รูปภาพทัวร์
// 2. วิดีโอทัวร์
// 3. PDF โปรแกรมทัวร์
// ==========================================================

const tourStorage = new CloudinaryStorage({

  cloudinary: cloudinary,

  params: {

    folder: 'triptour_uploads/tours',

    // ให้ Cloudinary ตรวจประเภทไฟล์เอง
    resource_type: 'auto',

    allowed_formats: [

      // IMAGE
      'jpg',
      'jpeg',
      'png',
      'webp',

      // VIDEO
      'mp4',
      'mov',
      'avi',
      'mkv',
      'webm',

      // PDF
      'pdf'

    ]

  }

});


// ==========================================================
// TOUR UPLOAD
// ==========================================================

export const tourUpload = multer({

  storage: tourStorage,

  limits: {

    // จำกัดไฟล์แต่ละไฟล์ไม่เกิน 100 MB
    fileSize: 100 * 1024 * 1024

  }

});