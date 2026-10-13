import express from 'express';
import admin from '../../config/firebase.js';

export const router = express.Router();

const ADMIN_EMAILS = (
  process.env.ADMIN_EMAILS || process.env.ADMIN_EMAIL 
)
  .split(',')
  .map((value) => value.trim().toLowerCase())
  .filter(Boolean);

async function isAdminUser(email) {
  const normalizedEmail = String(email || '').trim().toLowerCase();

  if (!normalizedEmail) {
    return false;
  }

  if (ADMIN_EMAILS.includes(normalizedEmail)) {
    return true;
  }

  try {
    const user = await admin.auth().getUserByEmail(normalizedEmail);
    const customRole = user.customClaims?.role;
    return customRole === 'admin' || customRole === 'superadmin';
  } catch {
    return false;
  }
}

router.post('/verify-token', async (req, res) => {
  const { idToken } = req.body || {};

  if (!idToken || typeof idToken !== 'string') {
    return res.status(400).json({
      success: false,
      message: 'Missing Firebase ID token',
    });
  }

  try {
    const decoded = await admin.auth().verifyIdToken(idToken);
    const email = String(decoded.email || '').trim().toLowerCase();

    if (!email) {
      return res.status(401).json({
        success: false,
        message: 'ไม่พบอีเมลใน Firebase token',
      });
    }

    const isAdmin = await isAdminUser(email);
    if (!isAdmin) {
      return res.status(403).json({
        success: false,
        message: 'บัญชีนี้ไม่ได้รับสิทธิ์ให้เข้าสู่ระบบแอดมิน',
      });
    }

    const token = Buffer.from(
      JSON.stringify({
        uid: decoded.uid,
        email,
        role: 'admin',
        issuedAt: Date.now(),
      }),
    ).toString('base64');

    return res.status(200).json({
      success: true,
      message: 'เข้าสู่ระบบสำเร็จ',
      token,
      user: {
        email,
        role: 'admin',
      },
    });
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: error instanceof Error ? error.message : 'Firebase token validation failed',
    });
  }
});

router.get('/me', (req, res) => {
  const authHeader = req.headers.authorization || '';
  const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : '';

  if (!token) {
    return res.status(401).json({
      success: false,
      message: 'Token missing',
    });
  }

  try {
    const payload = JSON.parse(Buffer.from(token, 'base64').toString('utf8'));

    if (payload.role !== 'admin' || !ADMIN_EMAILS.includes((payload.email || '').trim().toLowerCase())) {
      return res.status(401).json({
        success: false,
        message: 'Invalid token',
      });
    }

    return res.status(200).json({
      success: true,
      user: {
        email: payload.email,
        role: payload.role,
      },
    });
  } catch {
    return res.status(401).json({
      success: false,
      message: 'Invalid token',
    });
  }
});
