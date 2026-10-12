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

// Export configuration เดิมให้ Controller เรียกใช้
export { cloudinary };

// โฟลเดอร์ Cloudinary สำหรับเก็บรูปทัวร์
export const TOUR_CLOUD_FOLDER = 'triptour_uploads/tours';


// ==========================================================
// STORAGE เดิม
// ใช้กับ image / passport / slip / passenger
// ห้ามเปลี่ยนพฤติกรรมเดิม
// ==========================================================

const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'triptour_uploads/userAndslip',

    allowed_formats: [
      'jpg',
      'jpeg',
      'png',
      'webp'
    ]
  }
});

export const upload = multer({
  storage
});


// Storage สำหรับรูปภาพทั่วไป / รูปโปรไฟล์ Guide
const storageGuide = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'triptour_uploads/guides', 
    allowed_formats: ['jpg', 'jpeg', 'png', 'webp']
  }
});


// ใช้ของเดิมต่อไป
export const upload_guide = multer({
   storage: storageGuide
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

// ==========================================================
// ตรวจสอบรูปที่เลือกจาก Cloudinary
// ใช้ public_id เพื่อให้ Backend ตรวจสอบไฟล์จริง
// รองรับการตรวจสอบเป็นชุด ชุดละไม่เกิน 100 รูป
// ==========================================================

export async function resolveTourCloudImages(publicIds = []) {
  if (!Array.isArray(publicIds)) {
    throw new Error('รายการรูปจาก Cloudinary ต้องเป็น Array');
  }

  const ids = [
    ...new Set(
      publicIds
        .map((id) => String(id ?? '').trim())
        .filter(Boolean)
    )
  ];

  if (ids.length === 0) {
    return [];
  }

  const resources = [];

  // Cloudinary API รองรับการค้นรายละเอียดหลาย public_id ต่อชุด
  for (let i = 0; i < ids.length; i += 100) {
    const batch = ids.slice(i, i + 100);

    const result = await cloudinary.api.resources_by_ids(
      batch,
      {
        resource_type: 'image',
        type: 'upload',
      }
    );

    resources.push(...(result.resources ?? []));
  }

  const folderPrefix = `${TOUR_CLOUD_FOLDER}/`;
  const resourceMap = new Map();

  for (const resource of resources) {
    const publicId = String(resource.public_id ?? '');
    const assetFolder = String(resource.asset_folder ?? '');

    const belongsToTourFolder =
      publicId.startsWith(folderPrefix) ||
      assetFolder === TOUR_CLOUD_FOLDER ||
      assetFolder.startsWith(folderPrefix);

    if (
      resource.resource_type === 'image' &&
      resource.secure_url &&
      belongsToTourFolder
    ) {
      resourceMap.set(publicId, resource);
    }
  }

  // ปฏิเสธภาพที่ไม่มีอยู่จริง ไม่ใช่รูปภาพ
  // หรือไม่ได้อยู่ในคลังรูปทัวร์ที่อนุญาต
  const invalidIds = ids.filter(
    (id) => !resourceMap.has(id)
  );

  if (invalidIds.length > 0) {
    throw new Error(
      'พบรูปภาพที่ไม่ถูกต้อง หรือไม่อยู่ในโฟลเดอร์รูปทัวร์ Cloudinary'
    );
  }

  // คืนข้อมูลตามลำดับที่ผู้ใช้เลือก
  return ids.map((publicId) => {
    const resource = resourceMap.get(publicId);

    return {
      public_id: resource.public_id,
      secure_url: resource.secure_url,
      width: resource.width,
      height: resource.height,
      format: resource.format,
    };
  });
}