/**
 * ฟังก์ชันตรวจสอบจำนวนผู้ชำระเงิน และปรับสถานะรอบทัวร์เป็น 'close' อัตโนมัติเมื่อเต็มจำนวน
 * @param {Object} dbConnection - MySQL Connection หรือ Connection Pool
 * @param {number} roundId - ID ของรอบทัวร์ที่ต้องการเช็ค
 * @returns {Object} ข้อมูลสรุปจำนวนผู้โดยสารและสถานะรอบ
 */
export async function checkAndUpdateRoundStatus(dbConnection, roundId) {
  // (payment_status = 'paid') ในรอบทัวร์นี้
  const [sumResult] = await dbConnection.query(
    `SELECT 
       (COUNT(DISTINCT b.booking_id) + COUNT(p.passenger_id)) AS total_paid
     FROM booking b
     LEFT JOIN passenger p ON b.booking_id = p.booking_id
     WHERE b.round_id = ? AND LOWER(b.payment_status) = 'paid'`,
    [roundId],
  );

  const totalPaid = sumResult[0]?.total_paid || 0;

  // ดึงจำนวนที่นั่งสูงสุด (count) และสถานะปัจจุบันของรอบทัวร์
  const [roundRows] = await dbConnection.query(
    `SELECT count, status FROM tour_round WHERE round_id = ?`,
    [roundId],
  );

  if (!roundRows || roundRows.length === 0) {
    throw new Error(`Round ID ${roundId} not found`);
  }

  const roundCount = roundRows[0].count;
  let currentStatus = roundRows[0].status;

  //ถ้ายอดผู้เดินทาง >= count ให้ปรับสถานะรอบเป็น 'close'
  if (totalPaid >= roundCount && currentStatus !== 'closed') {
    await dbConnection.query(
      `UPDATE tour_round SET status = 'closed' WHERE round_id = ?`,
      [roundId],
    );
    currentStatus = 'close';
  }

  return {
    round_id: Number(roundId),
    total_paid: totalPaid,
    round_capacity: roundCount,
    status: currentStatus,
    is_closed: currentStatus === 'close',
  };
}