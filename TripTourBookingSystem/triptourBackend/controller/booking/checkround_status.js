/**
 * ตรวจสอบจำนวนผู้โดยสารที่ใช้ seats แล้วปิดรอบเมื่อเต็ม
 * การนับ seat ต้องใช้จำนวนผู้โดยสารจริงในแต่ละ booking
 * ไม่ใช่จำนวน booking + จำนวน passenger เพราะจะทำให้มีการ double-count
 */
export async function checkAndUpdateRoundStatus(dbConnection, roundId) {
  const [roundRows] = await dbConnection.query(
    `SELECT count, status FROM tour_round WHERE round_id = ? FOR UPDATE`,
    [roundId],
  );

  if (!roundRows || roundRows.length === 0) {
    throw new Error(`Round ID ${roundId} not found`);
  }

  const [sumResult] = await dbConnection.query(
    `SELECT COALESCE(SUM(seat_count), 0) AS total_paid
     FROM (
       SELECT 1 + COUNT(p.passenger_id) AS seat_count
       FROM booking b
       LEFT JOIN passenger p ON p.booking_id = b.booking_id
       WHERE b.round_id = ? AND LOWER(b.payment_status) = 'paid'
       GROUP BY b.booking_id
     ) t`,
    [roundId],
  );

  const totalPaid = Number(sumResult[0]?.total_paid || 0);
  const roundCount = Number(roundRows[0].count);
  let currentStatus = roundRows[0].status;

  if (totalPaid >= roundCount && currentStatus === "open") {
  await dbConnection.query(
    `UPDATE tour_round
     SET status = 'closed'
     WHERE round_id = ?`,
    [roundId]
  );

  currentStatus = "closed";
}

  return {
    round_id: Number(roundId),
    total_paid: totalPaid,
    round_capacity: roundCount,
    status: currentStatus,
    is_closed: currentStatus === 'closed',
  };
}