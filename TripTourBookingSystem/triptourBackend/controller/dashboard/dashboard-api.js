import express from 'express';
import { conn } from '../../config/db.js';

export const router = express.Router();

// ---------------------------------------------------------------------
// ค่าคงที่และตัวช่วย
// ---------------------------------------------------------------------

const TOP_COUNTRY_LIMIT = 5;

// format ของแกน X ใน chart ตาม rangeType (whitelist)
const CHART_DATE_FORMAT_BY_RANGE_TYPE = {
  all: '%Y',          // รายปี
  year: '%Y-%m',      // รายเดือน
  custom: '%Y-%m-%d', // รายวัน / กำหนดเอง
};

// เงื่อนไขของ booking ที่นับเป็นรายได้ (ใช้ร่วมกันทั้ง income, chart, revenueByCountry)
const PAID_INCOME_CONDITION = `
  b.payment_status = 'paid'
  AND b.status IN ('confirmed', 'finish')`;

const isValidDateString = (value) =>
  typeof value === 'string' &&
  /^\d{4}-\d{2}-\d{2}$/.test(value) &&
  !Number.isNaN(new Date(value).getTime());

const isValidDateRange = (startDate, endDate) =>
  isValidDateString(startDate) &&
  isValidDateString(endDate) &&
  new Date(startDate) <= new Date(endDate);

// สร้างเงื่อนไขช่วงวันที่ของ booking_date (endDate เป็น inclusive)
// คืนค่า SQL ที่ต่อท้าย WHERE ... ได้เลย (ขึ้นต้นด้วย AND)
const buildBookingDateCondition = (isAllRange) =>
  isAllRange
    ? ''
    : `AND b.booking_date >= ?
       AND b.booking_date < DATE_ADD(?, INTERVAL 1 DAY)`;

const toNumber = (value) => Number(value || 0);

const toChartPoints = (rows) =>
  (rows || []).map((row) => ({
    label: row.label,
    value: toNumber(row.value),
  }));

// ---------------------------------------------------------------------
// GET /overview
// query: startDate, endDate (YYYY-MM-DD), rangeType = 'year' | 'all' | 'custom'
// ---------------------------------------------------------------------
router.get('/overview', async (req, res) => {
  try {
    let { startDate, endDate, rangeType = 'year' } = req.query;

    const isAllRange = rangeType === 'all';

    // ไม่ได้ส่งช่วงวันที่มา -> ใช้ทั้งปีปัจจุบัน
    if (!isAllRange && (!startDate || !endDate)) {
      const currentYear = new Date().getFullYear();
      startDate = `${currentYear}-01-01`;
      endDate = `${currentYear}-12-31`;
    }

    if (!isAllRange && !isValidDateRange(startDate, endDate)) {
      return res.status(400).json({
        success: false,
        message: 'กรุณาระบุช่วงวันที่ที่ถูกต้อง',
      });
    }

    const chartDateFormat =
      CHART_DATE_FORMAT_BY_RANGE_TYPE[rangeType] ??
      CHART_DATE_FORMAT_BY_RANGE_TYPE.custom;

    const bookingDateCondition = buildBookingDateCondition(isAllRange);
    const dateParams = isAllRange ? [] : [startDate, endDate];

        // 1) สมาชิกทั้งหมด (Active)
    const totalUsersQuery = conn.query("SELECT COUNT(*) AS totalMembers FROM member WHERE status = 'active'");
    const totalGuideQuery = conn.query("SELECT COUNT(*) AS totalGuide FROM guide WHERE status = 'active'");

    // 2) รายได้รวม
    const totalIncomeQuery = conn.query(
      `SELECT COALESCE(SUM(b.total_price), 0) AS totalIncome
         FROM booking b
        WHERE ${PAID_INCOME_CONDITION}
          ${bookingDateCondition}`,
      dateParams
    );

    // 3) ผู้เดินทางที่แจ้งรายชื่อแล้ว (passenger ของ booking ที่ไม่ถูกยกเลิก/ปฏิเสธ)
    const toldTravelersQuery = conn.query(
  `SELECT COUNT(DISTINCT b.booking_id) + COUNT(p.passenger_id) AS toldTravelers
     FROM booking b
     LEFT JOIN passenger p ON p.booking_id = b.booking_id
    WHERE b.status NOT IN ('cancelled', 'reject', 'pending')
      ${bookingDateCondition}`,
  dateParams
);

    const bookingStatusCountsQuery = conn.query(
      `SELECT
         -- คนที่แอดมินยืนยันแล้ว (สถานะ confirmed)
         COUNT(DISTINCT CASE WHEN b.status = 'confirmed' AND b.payment_status IN ('paid', 'pending')
                             THEN b.booking_id END) AS confirmedUsers,
         
         -- คนที่เดินทางเสร็จสิ้นแล้ว (สถานะ finish)
         COUNT(DISTINCT CASE WHEN b.status = 'finish' AND b.payment_status = 'paid'
                             THEN b.booking_id END) AS finishedUsers,
         
         -- คนที่จ่ายเงินแล้ว
         COUNT(DISTINCT CASE WHEN b.payment_status = 'paid' AND b.status IN ('confirmed', 'finish', 'pending')
                             THEN b.booking_id END) AS paidUsers,
         
         -- จ่ายเงินแล้ว แต่สถานะการจองยังรอตรวจสอบ (pending)
         COUNT(DISTINCT CASE WHEN b.payment_status = 'paid' AND b.status = 'pending'
                             THEN b.booking_id END) AS pendingConfirmation,
         
         -- ยังไม่จ่ายเงิน และสถานะการจองรออยู่ (pending)
         COUNT(DISTINCT CASE WHEN b.payment_status = 'pending' AND b.status = 'pending'
                             THEN b.booking_id END) AS pendingPayment
         FROM booking b
        WHERE 1 = 1
          ${bookingDateCondition}`,
      dateParams
    );

    // 5) chart รายได้ตามช่วงเวลา
    const incomeChartQuery = conn.query(
      `SELECT DATE_FORMAT(b.booking_date, '${chartDateFormat}') AS label,
              SUM(b.total_price) AS value
         FROM booking b
        WHERE ${PAID_INCOME_CONDITION}
          ${bookingDateCondition}
        GROUP BY label
        ORDER BY label ASC`,
      dateParams
    );

    // 6) รายได้แยกประเทศ (Top 5)
   const revenueByCountryQuery = conn.query(
      `SELECT COALESCE(c.country_name_th, 'ไม่ระบุ') AS label,
              SUM(b.total_price) AS value
         FROM booking b
         LEFT JOIN tour_round tr ON tr.round_id   = b.round_id
         LEFT JOIN tour t        ON t.tour_id     = tr.tour_id
         LEFT JOIN country c     ON c.country_id  = t.country_id
        WHERE ${PAID_INCOME_CONDITION}
          ${bookingDateCondition}
        GROUP BY c.country_id, c.country_name_th
        ORDER BY value DESC
        LIMIT ${TOP_COUNTRY_LIMIT}`,
      dateParams
    );

  // 7) ผู้เดินทางแยกประเทศ (Top 5) = (1 คนจองหลัก + จำนวน passenger ในแต่ละ booking) แยกตามประเทศ
    const travelersByCountryQuery = conn.query(
      `SELECT COALESCE(c.country_name_th, 'ไม่ระบุ') AS label,
              SUM(1 + (SELECT COUNT(*) FROM passenger p WHERE p.booking_id = b.booking_id)) AS value
         FROM booking b
         LEFT JOIN tour_round tr ON tr.round_id   = b.round_id
         LEFT JOIN tour t        ON t.tour_id     = tr.tour_id
         LEFT JOIN country c     ON c.country_id  = t.country_id
        WHERE b.status NOT IN ('cancelled', 'reject', 'pending')
          ${bookingDateCondition}
        GROUP BY c.country_id, c.country_name_th
        ORDER BY value DESC
        LIMIT ${TOP_COUNTRY_LIMIT}`,
      dateParams
    );
   

    const [
      [totalMembersRows],
      [totalGuideRows],
      [totalIncomeRows],
      [toldTravelersRows],
      [bookingStatusCountsRows],
      [incomeChartRows],
      [revenueByCountryRows],
      [travelersByCountryRows],
    ] = await Promise.all([
      totalUsersQuery,
      totalGuideQuery,
      totalIncomeQuery,
      toldTravelersQuery,
      bookingStatusCountsQuery,
      incomeChartQuery,
      revenueByCountryQuery,
      travelersByCountryQuery,
    ]);

    const totalMembersCount = toNumber(totalMembersRows[0]?.totalMembers);
    const totalGuideCount = toNumber(totalGuideRows[0]?.totalGuide);
    const combinedTotalUsers = totalMembersCount + totalGuideCount;

    const bookingStatusCounts = bookingStatusCountsRows[0] || {};

    return res.status(200).json({
      success: true,
      data: {
        summary: {
         totalIncome: toNumber(totalIncomeRows[0]?.totalIncome),
          totalUsers: combinedTotalUsers,
          toldTravelers: toNumber(toldTravelersRows[0]?.toldTravelers),
          confirmedUsers: toNumber(bookingStatusCounts.confirmedUsers), // แอดมินยืนยันแล้ว
          finishedUsers: toNumber(bookingStatusCounts.finishedUsers),   // เดินทางเสร็จสิ้นแล้ว 
          paidUsers: toNumber(bookingStatusCounts.paidUsers),
          pendingConfirmation: toNumber(bookingStatusCounts.pendingConfirmation),
          pendingPayment: toNumber(bookingStatusCounts.pendingPayment),
        },
        chart: toChartPoints(incomeChartRows),
        revenueByCountry: toChartPoints(revenueByCountryRows),
        usersByCountry: toChartPoints(travelersByCountryRows),
      },
    });
  } catch (error) {
    console.error('Error fetching dashboard overview:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message,
    });
  }
});