import express from "express";
import { conn } from "../../config/db.js";
import admin from "../../config/firebase.js";

export const router = express.Router();
export default router;

const db = admin.database();

// ==========================================================
// HELPER : สร้าง Room ID จาก round_id
// ==========================================================

function getRoomId(roundId) {
  return `round_${Number(roundId)}`;
}

// ==========================================================
// HELPER : แปลงค่าว่างเป็น null
// ==========================================================

function emptyToNull(value) {
  if (value === undefined || value === null) {
    return null;
  }

  const text = String(value).trim();

  return text === "" ? null : text;
}

// ==========================================================
// HELPER : หา Firebase UID จาก Email
//
// ใช้ email ในตาราง guide
// แล้วไปค้น Firebase Authentication
// ==========================================================

async function getFirebaseUidByEmail(email) {
  if (!email || String(email).trim() === "") {
    return null;
  }

  try {
    const userRecord = await admin.auth().getUserByEmail(
      String(email).trim()
    );

    return userRecord.uid;
  } catch (error) {
    if (error?.code === "auth/user-not-found") {
      return null;
    }

    throw error;
  }
}

// ==========================================================
// HELPER : ดึงข้อมูล Guide
// ==========================================================

async function getGuideInfo(connection, guideId) {
  if (!guideId) {
    return {
      guide: null,
      firebase_uid: null,
    };
  }

  const [rows] = await connection.query(
    `
    SELECT
      guide_id,
      guide_code,
      first_name,
      last_name,
      email
    FROM guide
    WHERE guide_id = ?
    LIMIT 1
    `,
    [guideId]
  );

  if (rows.length === 0) {
    throw new Error("ไม่พบข้อมูล Guide");
  }

  const guide = rows[0];

  const firebaseUid = await getFirebaseUidByEmail(guide.email);

  return {
    guide,
    firebase_uid: firebaseUid,
  };
}

// ==========================================================
// HELPER : หา Firebase UID ของสมาชิกและ Guide ในรอบนี้
// ==========================================================
async function getRoundFirebaseUids(connection, roundId) {
  const [memberRows] = await connection.query(
    `SELECT DISTINCT m.google_id AS firebase_uid
     FROM booking b
     INNER JOIN member m ON m.member_id = b.member_id
     WHERE b.round_id = ?
       AND m.google_id IS NOT NULL
       AND TRIM(m.google_id) <> ''`,
    [roundId]
  );

  const [guideRows] = await connection.query(
    `SELECT g.email
     FROM tour_round tr
     LEFT JOIN guide g ON g.guide_id = tr.guide_id
     WHERE tr.round_id = ?
     LIMIT 1`,
    [roundId]
  );

  const uids = memberRows
    .map((row) => row.firebase_uid)
    .filter((uid) => typeof uid === "string" && uid.trim() !== "");

  const guideUid = await getFirebaseUidByEmail(guideRows[0]?.email);

  if (guideUid) {
    uids.push(guideUid);
  }

  return [...new Set(uids)];
}

// ==========================================================
// HELPER : สร้างข้อมูลห้อง Chat
// ==========================================================

function buildRoomData({
  roundId,
  tourId,
  tourName,
  startDate,
  endDate,
  guideUid,
}) {
  const now = Date.now();

  const members = {};

  if (guideUid) {
    members[guideUid] = "guide";
  }

  return {
    roomId: getRoomId(roundId),

    roomData: {
      roundId: Number(roundId),
      tourId: Number(tourId),

      roomName: `${tourName} - รอบที่ ${roundId}`,

      createdAt: now,
      createdBy: "admin",

      lastMessage: "",
      lastUpdated: now,

      startDate: startDate || null,
      endDate: endDate || null,

      members,
    },

    guideUid,
  };
}

// ==========================================================
// HELPER : สร้าง Firebase Room
// ==========================================================

async function createRoundChatRoom({
  roundId,
  tourId,
  tourName,
  startDate,
  endDate,
  guideUid,
}) {
  const roomId = getRoomId(roundId);

  const roomRef = db.ref(`rooms/${roomId}`);

  const existingSnapshot = await roomRef.get();

  if (existingSnapshot.exists()) {
    throw new Error(
      `Firebase Room ${roomId} มีอยู่แล้ว ไม่สามารถสร้างซ้ำได้`
    );
  }

  const roomInfo = buildRoomData({
    roundId,
    tourId,
    tourName,
    startDate,
    endDate,
    guideUid,
  });

  const updates = {};

  updates[`rooms/${roomId}`] = roomInfo.roomData;

  // ถ้ามี Guide
  if (guideUid) {
    updates[`user_rooms/${guideUid}/${roomId}`] = true;
  }

  await db.ref().update(updates);

  return {
    roomId,
    guideUid,
  };
}

// ==========================================================
// HELPER : ดึง Snapshot สำหรับใช้ Restore
// กรณี DELETE Firebase สำเร็จ แต่ MySQL มีปัญหา
// ==========================================================

async function getRoundFirebaseBackup(roundId, additionalUids = []) {
  const roomId = getRoomId(roundId);

  const roomRef = db.ref(`rooms/${roomId}`);
  const messageRef = db.ref(`messages/${roomId}`);

  const [roomSnapshot, messageSnapshot] = await Promise.all([
    roomRef.get(),
    messageRef.get(),
  ]);

  const restoreUpdates = {};

  if (roomSnapshot.exists()) {
    restoreUpdates[`rooms/${roomId}`] = roomSnapshot.val();
  }

  if (messageSnapshot.exists()) {
    restoreUpdates[`messages/${roomId}`] = messageSnapshot.val();
  }

  const roomData = roomSnapshot.val();
  const members = roomData?.members || {};

  // รวมสมาชิกใน Firebase Room กับ UID ที่ค้นจาก MySQL
  const memberUids = [
    ...new Set([
      ...Object.keys(members),
      ...additionalUids.filter(Boolean),
    ]),
  ];

  // สำรอง user_rooms ก่อนลบ เพื่อให้ Route ลบรอบเดิม Restore กลับได้
  for (const uid of memberUids) {
    const userRoomSnapshot = await db
      .ref(`user_rooms/${uid}/${roomId}`)
      .get();

    if (userRoomSnapshot.exists()) {
      restoreUpdates[`user_rooms/${uid}/${roomId}`] =
        userRoomSnapshot.val();
    }
  }

  return {
    restoreUpdates,
    memberUids,
  };
}

// ==========================================================
// HELPER : ลบ Firebase Room
// ==========================================================

async function deleteRoundChatRoom(roundId, additionalUids = []) {
  const roomId = getRoomId(roundId);

  const backup = await getRoundFirebaseBackup(roundId, additionalUids);

  const updates = {
    [`rooms/${roomId}`]: null,
    [`messages/${roomId}`]: null,
  };

  for (const uid of backup.memberUids) {
    updates[`user_rooms/${uid}/${roomId}`] = null;
  }

  // ลบหลาย Path พร้อมกัน
  // เรียกซ้ำได้ หาก Path เหล่านั้นถูกลบไปแล้ว
  await db.ref().update(updates);

  // คืนค่าเดิมไว้ให้ Route DELETE ที่มีระบบ Restore อยู่แล้ว
  return backup.restoreUpdates;
}

// ==========================================================
// HELPER : Restore Firebase
// ==========================================================

async function restoreRoundChatRoom(restoreUpdates) {
  if (!restoreUpdates || Object.keys(restoreUpdates).length === 0) {
    return;
  }

  await db.ref().update(restoreUpdates);
}

// ==========================================================
// HELPER : Sync Firebase Room ตอนแก้ไขรอบ
// ==========================================================

async function syncRoundChatRoom({
  roundId,
  tourId,
  tourName,
  startDate,
  endDate,
  guideUid,
}) {
  const roomId = getRoomId(roundId);

  const roomRef = db.ref(`rooms/${roomId}`);

  const roomSnapshot = await roomRef.get();

  // ========================================================
  // ถ้ายังไม่มี Room
  // ให้สร้างใหม่
  // ========================================================

  if (!roomSnapshot.exists()) {
    return createRoundChatRoom({
      roundId,
      tourId,
      tourName,
      startDate,
      endDate,
      guideUid,
    });
  }

  const currentRoom = roomSnapshot.val() || {};
  const currentMembers = currentRoom.members || {};

  const updates = {};

  updates[`rooms/${roomId}/roundId`] = Number(roundId);
  updates[`rooms/${roomId}/tourId`] = Number(tourId);

  updates[`rooms/${roomId}/roomName`] =
    `${tourName} - รอบที่ ${roundId}`;

  updates[`rooms/${roomId}/startDate`] =
    startDate || null;

  updates[`rooms/${roomId}/endDate`] =
    endDate || null;

  updates[`rooms/${roomId}/lastUpdated`] =
    Date.now();

  // ========================================================
  // ลบ Guide เก่าทั้งหมด
  // ========================================================

  for (const [uid, role] of Object.entries(currentMembers)) {
    if (role === "guide" && uid !== guideUid) {
      updates[`rooms/${roomId}/members/${uid}`] = null;
      updates[`user_rooms/${uid}/${roomId}`] = null;
    }
  }

  // ========================================================
  // เพิ่ม Guide ใหม่
  // ========================================================

  if (guideUid) {
    updates[`rooms/${roomId}/members/${guideUid}`] =
      "guide";

    updates[`user_rooms/${guideUid}/${roomId}`] =
      true;
  }

  await db.ref().update(updates);

  return {
    roomId,
    guideUid,
  };
}

// ==========================================================
// GET /manage-round/tour/:tourId
//
// ดึง:
// - ข้อมูล Tour
// - รอบทั้งหมด
// - Guide ทั้งหมด
// ==========================================================

router.get("/tour/:tourId", async (req, res) => {
  const tourId = Number(req.params.tourId);

  if (!tourId || Number.isNaN(tourId)) {
    return res.status(400).json({
      success: false,
      message: "tour_id ไม่ถูกต้อง",
    });
  }

  try {
    // ======================================================
    // TOUR
    // ======================================================

    const [tourRows] = await conn.query(
  `
  SELECT
    tour_id,
    tour_name,
    status,
    include_flight
  FROM tour
  WHERE tour_id = ?
  LIMIT 1
  `,
  [tourId]
);

    if (tourRows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "ไม่พบข้อมูลทัวร์",
      });
    }

    // ======================================================
    // ROUNDS
    // ======================================================

    const [roundRows] = await conn.query(
      `
      SELECT
        tr.*,

        g.guide_code,
        g.first_name AS guide_first_name,
        g.last_name AS guide_last_name,
        g.email AS guide_email

      FROM tour_round tr

      LEFT JOIN guide g
        ON g.guide_id = tr.guide_id

      WHERE tr.tour_id = ?

      ORDER BY
        tr.start_date ASC,
        tr.round_id ASC
      `,
      [tourId]
    );

    const rounds = roundRows.map((round) => ({
      ...round,
      chat_room_id: getRoomId(round.round_id),
    }));

    // ======================================================
    // GUIDES
    // ======================================================

    const [guideRows] = await conn.query(
      `
      SELECT
        guide_id,
        guide_code,
        first_name,
        last_name,
        email
      FROM guide
      ORDER BY first_name ASC, last_name ASC
      `
    );

    return res.status(200).json({
      success: true,

      data: {
        tour: tourRows[0],
        rounds,
        guides: guideRows,
      },
    });
  } catch (error) {
    console.error(
      "GET /manage-round/tour/:tourId error:",
      error
    );

    return res.status(500).json({
      success: false,
      message: "ไม่สามารถโหลดข้อมูลรอบทัวร์ได้",
      error: error.message,
    });
  }
});

// ==========================================================
// POST /manage-round
//
// สร้างรอบ + สร้าง Firebase Room อัตโนมัติ
// ==========================================================

router.post("/", async (req, res) => {
  let connection = null;
  let insertedRoundId = null;
  let firebaseCreated = false;

  try {
    const {
      round_code,
      tour_id,
      departure,
      destination,
      start_date,
      end_date,
      airline,
      flight,
      flight_time,
      price_single,
      price_double,
      price_triple,
      count,
      guide_id,
      status,
    } = req.body || {};

    const normalizedRoundCode = String(round_code ?? "").trim().toUpperCase();

    // ======================================================
    // VALIDATE
    // ======================================================

    if (!normalizedRoundCode) {
  return res.status(400).json({
    success: false,
    message: "กรุณาระบุรหัสรอบทัวร์",
  });
}

if (normalizedRoundCode.length > 50) {
  return res.status(400).json({
    success: false,
    message: "รหัสรอบทัวร์ต้องมีความยาวไม่เกิน 50 ตัวอักษร",
  });
}

    if (!tour_id || Number.isNaN(Number(tour_id))) {
      return res.status(400).json({
        success: false,
        message: "tour_id ไม่ถูกต้อง",
      });
    }

    if (!departure?.trim()) {
      return res.status(400).json({
        success: false,
        message: "กรุณาระบุจุดออกเดินทาง",
      });
    }

    if (!destination?.trim()) {
      return res.status(400).json({
        success: false,
        message: "กรุณาระบุจุดหมายปลายทาง",
      });
    }

    if (!start_date || !end_date) {
      return res.status(400).json({
        success: false,
        message: "กรุณาระบุวันที่เริ่มและวันที่สิ้นสุด",
      });
    }

    if (
      new Date(start_date).getTime() >
      new Date(end_date).getTime()
    ) {
      return res.status(400).json({
        success: false,
        message: "วันเริ่มทัวร์ต้องไม่มากกว่าวันสิ้นสุด",
      });
    }

    if (
      price_single === undefined ||
      price_single === null ||
      price_single === "" ||
      Number.isNaN(Number(price_single)) ||
      Number(price_single) < 0
    ) {
      return res.status(400).json({
        success: false,
        message: "ราคาบุคคลเดี่ยวไม่ถูกต้อง",
      });
    }

    if (
      price_double === undefined ||
      price_double === null ||
      price_double === "" ||
      Number.isNaN(Number(price_double)) ||
      Number(price_double) < 0
    ) {
      return res.status(400).json({
        success: false,
        message: "ราคาห้องคู่ไม่ถูกต้อง",
      });
    }

    if (
      price_triple === undefined ||
      price_triple === null ||
      price_triple === "" ||
      Number.isNaN(Number(price_triple)) ||
      Number(price_triple) < 0
    ) {
      return res.status(400).json({
        success: false,
        message: "ราคาห้องสามคนไม่ถูกต้อง",
      });
    }

    if (
      count === undefined ||
      count === null ||
      count === "" ||
      Number.isNaN(Number(count)) ||
      Number(count) < 1
    ) {
      return res.status(400).json({
        success: false,
        message: "จำนวนที่นั่งต้องมากกว่า 0",
      });
    }

const normalizedStatus =
  ["open", "closed", "success"].includes(status)
    ? status
    : "open";

    const normalizedGuideId =
      guide_id === "" ||
      guide_id === null ||
      guide_id === undefined
        ? null
        : Number(guide_id);

    connection = await conn.getConnection();

    await connection.beginTransaction();

    const [duplicateCodeRows] = await connection.query(
  `
  SELECT round_id
  FROM tour_round
  WHERE round_code = ?
  LIMIT 1
  `,
  [normalizedRoundCode]
);

if (duplicateCodeRows.length > 0) {
  await connection.rollback();

  return res.status(409).json({
    success: false,
    message: "รหัสรอบทัวร์นี้มีอยู่แล้ว กรุณาใช้รหัสอื่น",
  });
}

    // ======================================================
    // ตรวจ Tour
    // ======================================================

    const [tourRows] = await connection.query(
  `
  SELECT
    tour_id,
    tour_name,
    include_flight
  FROM tour
  WHERE tour_id = ?
  LIMIT 1
  `,
  [Number(tour_id)]
);

    if (tourRows.length === 0) {
      await connection.rollback();

      return res.status(404).json({
        success: false,
        message: "ไม่พบข้อมูลทัวร์",
      });
    }

    const tour = tourRows[0];

    // ======================================================
// ตรวจว่ารวมตั๋วเครื่องบินหรือไม่
// ======================================================

const isFlightIncluded =
  String(tour.include_flight ?? '').trim() === 'รวม';

const savedAirline = isFlightIncluded
  ? emptyToNull(airline)
  : null;

const savedFlight = isFlightIncluded
  ? emptyToNull(flight)
  : null;

const savedFlightTime = isFlightIncluded
  ? emptyToNull(flight_time)
  : null;

    // ======================================================
    // GUIDE
    // ======================================================

    const guideInfo = await getGuideInfo(
      connection,
      normalizedGuideId
    );

    // ======================================================
    // INSERT ROUND
    // ======================================================

    const [result] = await connection.query(
  `
  INSERT INTO tour_round
  (
    round_code,
    tour_id,
    departure,
    destination,
    start_date,
    end_date,
    airline,
    flight,
    flight_time,
    price_single,
    price_double,
    price_triple,
    count,
    status,
    guide_id
  )
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `,
  [
    normalizedRoundCode,
    Number(tour_id),
    departure.trim(),
    destination.trim(),
    start_date,
    end_date,
    savedAirline,
    savedFlight,
    savedFlightTime,
    Number(price_single),
    Number(price_double),
    Number(price_triple),
    Number(count),
    normalizedStatus,
    normalizedGuideId,
  ]
);

insertedRoundId = result.insertId;

    // ======================================================
    // CREATE FIREBASE ROOM
    // ======================================================

    const firebaseRoom = await createRoundChatRoom({
      roundId: insertedRoundId,
      tourId: Number(tour_id),
      tourName: tour.tour_name,
      startDate: start_date,
      endDate: end_date,
      guideUid: guideInfo.firebase_uid,
    });

    firebaseCreated = true;

    // ======================================================
    // COMMIT
    // ======================================================

    await connection.commit();

    return res.status(201).json({
      success: true,
      message: "เพิ่มรอบทัวร์และสร้างห้องแชตสำเร็จ",

      data: {
        round_id: insertedRoundId,
        round_code: normalizedRoundCode,

        chat_room_id: firebaseRoom.roomId,

        guide_id: normalizedGuideId,

        guide_firebase_uid:
          guideInfo.firebase_uid,

        guide_chat_warning:
          normalizedGuideId && !guideInfo.firebase_uid
            ? "ไม่พบ Firebase UID ของ Guide จาก email จึงยังไม่ได้เพิ่ม Guide เข้าห้อง Chat"
            : null,
      },
    });
  } catch (error) {
    console.error(
      "POST /manage-round error:",
      error
    );

    if (connection) {
      try {
        await connection.rollback();
      } catch {}
    }

    // ======================================================
    // ถ้าสร้าง Firebase สำเร็จ แต่ MySQL ล้มเหลว
    // ลบ Firebase Room ที่เพิ่งสร้าง
    // ======================================================

    if (firebaseCreated && insertedRoundId) {
      try {
        await deleteRoundChatRoom(
          insertedRoundId
        );
      } catch (cleanupError) {
        console.error(
          "Firebase cleanup error:",
          cleanupError
        );
      }
    }
    if (
  error?.code === "ER_DUP_ENTRY" &&
  String(error?.message ?? "").includes("uq_tour_round_round_code")
) {
  return res.status(409).json({
    success: false,
    message: "รหัสรอบทัวร์นี้มีอยู่แล้ว กรุณาใช้รหัสอื่น",
  });
}

    return res.status(500).json({
      success: false,
      message: "ไม่สามารถเพิ่มรอบทัวร์ได้",
      error: error.message,
    });
  } finally {
    if (connection) {
      connection.release();
    }
  }
});

// ==========================================================
// PUT /manage-round/:roundId
//
// แก้ไขรอบ + Sync Firebase Room
// ==========================================================

router.put("/:roundId", async (req, res) => {
  const roundId = Number(req.params.roundId);

  if (!roundId || Number.isNaN(roundId)) {
    return res.status(400).json({
      success: false,
      message: "round_id ไม่ถูกต้อง",
    });
  }

  let connection = null;

  try {
    const {
      round_code,
      tour_id,
      departure,
      destination,
      start_date,
      end_date,
      airline,
      flight,
      flight_time,
      price_single,
      price_double,
      price_triple,
      count,
      guide_id,
      status,
    } = req.body || {};
const normalizedRoundCode = String(round_code ?? "").trim().toUpperCase();
    // ======================================================
    // VALIDATE
    // ======================================================

    if (!normalizedRoundCode) {
  return res.status(400).json({
    success: false,
    message: "กรุณาระบุรหัสรอบทัวร์",
  });
}

if (normalizedRoundCode.length > 50) {
  return res.status(400).json({
    success: false,
    message: "รหัสรอบทัวร์ต้องมีความยาวไม่เกิน 50 ตัวอักษร",
  });
}

    if (!tour_id || Number.isNaN(Number(tour_id))) {
      return res.status(400).json({
        success: false,
        message: "tour_id ไม่ถูกต้อง",
      });
    }

    if (!departure?.trim()) {
      return res.status(400).json({
        success: false,
        message: "กรุณาระบุจุดออกเดินทาง",
      });
    }

    if (!destination?.trim()) {
      return res.status(400).json({
        success: false,
        message: "กรุณาระบุจุดหมายปลายทาง",
      });
    }

    if (!start_date || !end_date) {
      return res.status(400).json({
        success: false,
        message: "กรุณาระบุวันที่เริ่มและวันที่สิ้นสุด",
      });
    }

    if (
      new Date(start_date).getTime() >
      new Date(end_date).getTime()
    ) {
      return res.status(400).json({
        success: false,
        message: "วันเริ่มทัวร์ต้องไม่มากกว่าวันสิ้นสุด",
      });
    }

    if (
      count === undefined ||
      count === null ||
      count === "" ||
      Number.isNaN(Number(count)) ||
      Number(count) < 1
    ) {
      return res.status(400).json({
        success: false,
        message: "จำนวนที่นั่งต้องมากกว่า 0",
      });
    }

    const normalizedGuideId =
      guide_id === "" ||
      guide_id === null ||
      guide_id === undefined
        ? null
        : Number(guide_id);

const normalizedStatus =
  ["open", "closed", "success"].includes(status)
    ? status
    : "open";

    connection = await conn.getConnection();

    await connection.beginTransaction();

    // ======================================================
    // ดึงข้อมูลเดิม
    // ======================================================

    const [existingRows] = await connection.query(
      `
      SELECT
        tr.*,

        t.tour_name,

        g.email AS old_guide_email

      FROM tour_round tr

      INNER JOIN tour t
        ON t.tour_id = tr.tour_id

      LEFT JOIN guide g
        ON g.guide_id = tr.guide_id

      WHERE tr.round_id = ?

      LIMIT 1
      `,
      [roundId]
    );

    if (existingRows.length === 0) {
      await connection.rollback();

      return res.status(404).json({
        success: false,
        message: "ไม่พบรอบทัวร์",
      });
    }

    const existingRound = existingRows[0];

if (existingRound.status === "success") {
  await connection.rollback();

  return res.status(409).json({
    success: false,
    message: "รอบทัวร์นี้จบแล้ว ไม่สามารถแก้ไขข้อมูลได้",
  });
}

    const [duplicateCodeRows] = await connection.query(
  `
  SELECT round_id
  FROM tour_round
  WHERE round_code = ?
    AND round_id <> ?
  LIMIT 1
  `,
  [normalizedRoundCode, roundId]
);

if (duplicateCodeRows.length > 0) {
  await connection.rollback();

  return res.status(409).json({
    success: false,
    message: "รหัสรอบทัวร์นี้มีอยู่แล้ว กรุณาใช้รหัสอื่น",
  });
}

    // ======================================================
    // ตรวจ Tour ใหม่
    // ======================================================

    const [tourRows] = await connection.query(
  `
  SELECT
    tour_id,
    tour_name,
    include_flight
  FROM tour
  WHERE tour_id = ?
  LIMIT 1
  `,
  [Number(tour_id)]
);

    if (tourRows.length === 0) {
      await connection.rollback();

      return res.status(404).json({
        success: false,
        message: "ไม่พบข้อมูลทัวร์",
      });
    }

    const tour = tourRows[0];

    // ======================================================
// ตรวจว่ารวมตั๋วเครื่องบินหรือไม่
// ======================================================

const isFlightIncluded =
  String(tour.include_flight ?? '').trim() === 'รวม';

    // ======================================================
    // GUIDE ใหม่
    // ======================================================

    const guideInfo = await getGuideInfo(
      connection,
      normalizedGuideId
    );

    // ======================================================
    // GUIDE เดิม
    // ======================================================

    const oldGuideUid =
      await getFirebaseUidByEmail(
        existingRound.old_guide_email
      );

    // ======================================================
    // UPDATE MYSQL
    // ======================================================

    await connection.query(
  `
  UPDATE tour_round
  SET
    round_code = ?,
    tour_id = ?,
    departure = ?,
    destination = ?,
    start_date = ?,
    end_date = ?,
    airline = ?,
    flight = ?,
    flight_time = ?,
    price_single = ?,
    price_double = ?,
    price_triple = ?,
    count = ?,
    status = ?,
    guide_id = ?
  WHERE round_id = ?
  `,
  [
    normalizedRoundCode,
    Number(tour_id),
    departure.trim(),
    destination.trim(),
    start_date,
    end_date,
    isFlightIncluded ? emptyToNull(airline) : null,
    isFlightIncluded ? emptyToNull(flight) : null,
    isFlightIncluded ? emptyToNull(flight_time) : null,
    Number(price_single),
    Number(price_double),
    Number(price_triple),
    Number(count),
    normalizedStatus,
    normalizedGuideId,
    roundId,
  ]
);

    // ======================================================
    // SYNC FIREBASE
    // ======================================================

    const firebaseRoom =
      await syncRoundChatRoom({
        roundId,
        tourId: Number(tour_id),
        tourName: tour.tour_name,
        startDate: start_date,
        endDate: end_date,
        guideUid: guideInfo.firebase_uid,
      });

    // ======================================================
    // COMMIT
    // ======================================================

    await connection.commit();

    return res.status(200).json({
      success: true,
      message: "แก้ไขรอบทัวร์สำเร็จ",

      data: {
        round_id: roundId,
        round_code: normalizedRoundCode,

        chat_room_id: firebaseRoom.roomId,

        guide_id: normalizedGuideId,

        old_guide_firebase_uid:
          oldGuideUid,

        guide_firebase_uid:
          guideInfo.firebase_uid,

        guide_chat_warning:
          normalizedGuideId && !guideInfo.firebase_uid
            ? "ไม่พบ Firebase UID ของ Guide จาก email จึงยังไม่ได้เพิ่ม Guide เข้าห้อง Chat"
            : null,
      },
    });
  } catch (error) {
    if (connection) {
      try {
        await connection.rollback();
      } catch {}
    }
    if (
  error?.code === "ER_DUP_ENTRY" &&
  String(error?.message ?? "").includes("uq_tour_round_round_code")
) {
  return res.status(409).json({
    success: false,
    message: "รหัสรอบทัวร์นี้มีอยู่แล้ว กรุณาใช้รหัสอื่น",
  });
}

    console.error(
      "PUT /manage-round/:roundId error:",
      error
    );

    return res.status(500).json({
      success: false,
      message: "ไม่สามารถแก้ไขรอบทัวร์ได้",
      error: error.message,
    });
  } finally {
    if (connection) {
      connection.release();
    }
  }
});

// ==========================================================
// POST /manage-round/:roundId/finish
// จบทัวร์ เปลี่ยนสถานะ Booking และลบ Firebase Chat
// ไม่ต้องเพิ่มคอลัมน์ติดตามการลบ Chat
// ==========================================================
router.post("/:roundId/finish", async (req, res) => {
  const roundId = Number(req.params.roundId);

  if (!roundId || Number.isNaN(roundId)) {
    return res.status(400).json({
      success: false,
      message: "round_id ไม่ถูกต้อง",
    });
  }

  let connection = null;
  let finishedBookings = 0;

  try {
    connection = await conn.getConnection();
    await connection.beginTransaction();

    // 1. ล็อกแถวรอบทัวร์ ป้องกันการจบทัวร์ซ้ำพร้อมกัน
    const [roundRows] = await connection.query(
      `SELECT round_id, status
       FROM tour_round
       WHERE round_id = ?
       FOR UPDATE`,
      [roundId]
    );

    if (roundRows.length === 0) {
      await connection.rollback();

      return res.status(404).json({
        success: false,
        message: "ไม่พบรอบทัวร์",
      });
    }

    const currentStatus = roundRows[0].status;

    // ถ้าเป็นการจบทัวร์ครั้งแรก ให้ตรวจสอบรายการที่รออนุมัติสลิปก่อน
    // ถ้าเป็นการลองลบห้องซ้ำ ไม่ต้องตรวจซ้ำ เพราะ MySQL จบทัวร์ไปแล้ว
    if (currentStatus !== "success") {
      const [pendingRows] = await connection.query(
        `SELECT COUNT(*) AS total
         FROM booking
         WHERE round_id = ?
           AND status = 'pending'
           AND payment_status = 'paid'`,
        [roundId]
      );

      const pendingCount = Number(pendingRows[0]?.total || 0);

      if (pendingCount > 0) {
        await connection.rollback();

        return res.status(409).json({
          success: false,
          message:
            `ยังจบทัวร์ไม่ได้ มีรายการส่งสลิปที่รอแอดมินตรวจสอบ ${pendingCount} รายการ กรุณาอนุมัติหรือปฏิเสธรายการเหล่านี้ก่อน`,
          pending_payment_reviews: pendingCount,
        });
      }

      // 2. ตั้งสถานะรอบทัวร์เป็นจบทัวร์แล้ว
      await connection.query(
        `UPDATE tour_round
         SET status = 'success'
         WHERE round_id = ?`,
        [roundId]
      );

      // 3. เปลี่ยนเฉพาะ Booking ที่ชำระเงินแล้วและแอดมินอนุมัติแล้ว
      await connection.query(
        `UPDATE booking
         SET status = 'finish'
         WHERE round_id = ?
           AND payment_status = 'paid'
           AND status = 'confirmed'`,
        [roundId]
      );
    }

    // นับจำนวน Booking ที่จบทัวร์แล้ว รวมถึงกรณีที่เรียก Route ซ้ำ
    const [finishedRows] = await connection.query(
      `SELECT COUNT(*) AS total
       FROM booking
       WHERE round_id = ?
         AND payment_status = 'paid'
         AND status = 'finish'`,
      [roundId]
    );

    finishedBookings = Number(finishedRows[0]?.total || 0);

    // 4. ยืนยันการบันทึก MySQL ก่อนทำงานกับ Firebase
    await connection.commit();
  } catch (error) {
    if (connection) {
      try {
        await connection.rollback();
      } catch {}
    }

    console.error("Finish round MySQL error:", error);

    return res.status(500).json({
      success: false,
      message: "ไม่สามารถบันทึกสถานะจบทัวร์ได้",
      error: error.message,
    });
  } finally {
    if (connection) {
      connection.release();
    }
  }

  // 5. ลบ Firebase หลังจากบันทึก MySQL สำเร็จแล้ว
  // ถ้าขั้นตอนนี้ล้มเหลว จะไม่ย้อน MySQL กลับ
  try {
    const participantUids = await getRoundFirebaseUids(conn, roundId);

    await deleteRoundChatRoom(roundId, participantUids);

    return res.status(200).json({
      success: true,
      message: "จบทัวร์และลบห้องแชทเรียบร้อยแล้ว",
      data: {
        round_id: roundId,
        status: "success",
        finished_bookings: finishedBookings,
        chat_room_id: getRoomId(roundId),
        chat_deleted: true,
      },
    });
  } catch (error) {
    console.error("Finish round Firebase cleanup error:", error);

    // MySQL จบทัวร์ไปแล้ว แต่ Firebase อาจยังลบไม่สำเร็จ
    // ส่ง tour_finished=true ให้ Angular ทราบว่าต้องไม่ย้อนสถานะ
    return res.status(503).json({
      success: false,
      tour_finished: true,
      message:
        "บันทึกจบทัวร์แล้ว แต่ลบห้องแชทไม่สำเร็จ กรุณากดลองลบห้องแชทอีกครั้ง",
      data: {
        round_id: roundId,
        status: "success",
        finished_bookings: finishedBookings,
        chat_room_id: getRoomId(roundId),
        can_retry: true,
      },
    });
  }
});

// ==========================================================
// DELETE /manage-round/:roundId
//
// ถ้ามี Booking -> ห้ามลบ
// ถ้าไม่มี Booking -> ลบ MySQL + Firebase
// ==========================================================

router.delete("/:roundId", async (req, res) => {
  const roundId = Number(req.params.roundId);

  if (!roundId || Number.isNaN(roundId)) {
    return res.status(400).json({
      success: false,
      message: "round_id ไม่ถูกต้อง",
    });
  }

  let connection = null;
  let firebaseBackup = null;
  let firebaseDeleted = false;

  try {
    connection = await conn.getConnection();

    await connection.beginTransaction();

    // ======================================================
    // ตรวจรอบ
    // ======================================================

    const [roundRows] = await connection.query(
  `SELECT round_id, tour_id, status
   FROM tour_round
   WHERE round_id = ?
   LIMIT 1`,
  [roundId]
);

    if (roundRows.length === 0) {
      await connection.rollback();

      return res.status(404).json({
        success: false,
        message: "ไม่พบรอบทัวร์",
      });
    }

    if (roundRows[0].status === "success") {
  await connection.rollback();

  return res.status(409).json({
    success: false,
    message: "รอบทัวร์นี้จบแล้ว ไม่สามารถลบรอบเพื่อป้องกันการสูญหายของประวัติได้",
  });
}

// ======================================================
// ตรวจ Booking
// ห้ามลบถ้ามี booking.status เป็น pending หรือ confirmed
// และ booking.payment_status เป็น paid
// ======================================================

const [bookingRows] = await connection.query(
  `
    SELECT COUNT(*) AS total
    FROM booking
    WHERE round_id = ?
      AND status IN ('pending', 'confirmed')
      AND payment_status = 'paid'
  `,
  [roundId]
);

const bookingCount = Number(bookingRows[0]?.total || 0);

if (bookingCount > 0) {
  await connection.rollback();

  return res.status(409).json({
    success: false,
    message:
      "ไม่สามารถลบรอบทัวร์ได้ เนื่องจากมีรายการจองสถานะ pending หรือ confirmed ที่ชำระเงินแล้ว",
    booking_count: bookingCount,
  });
}

    // ======================================================
    // ลบ Firebase ก่อน
    // ======================================================

const participantUids = await getRoundFirebaseUids(
  connection,
  roundId
);

firebaseBackup = await deleteRoundChatRoom(
  roundId,
  participantUids
);

firebaseDeleted = true;

    // ======================================================
    // ลบ MySQL
    // ======================================================

    await connection.query(
      `
      DELETE FROM tour_round
      WHERE round_id = ?
      `,
      [roundId]
    );

    await connection.commit();

    return res.status(200).json({
      success: true,
      message:
        "ลบรอบทัวร์และห้องแชตเรียบร้อยแล้ว",

      round_id: roundId,
      chat_room_id: getRoomId(roundId),
    });
  } catch (error) {
    if (connection) {
      try {
        await connection.rollback();
      } catch {}
    }

    // ======================================================
    // ถ้า Firebase ถูกลบไปแล้ว
    // Restore กลับ
    // ======================================================

    if (
      firebaseDeleted &&
      firebaseBackup &&
      Object.keys(firebaseBackup).length > 0
    ) {
      try {
        await restoreRoundChatRoom(
          firebaseBackup
        );
      } catch (restoreError) {
        console.error(
          "Firebase restore error:",
          restoreError
        );
      }
    }

    console.error(
      "DELETE /manage-round/:roundId error:",
      error
    );

    return res.status(500).json({
      success: false,
      message:
        "ไม่สามารถลบรอบทัวร์ได้",
      error: error.message,
    });
  } finally {
    if (connection) {
      connection.release();
    }
  }
});