import express from "express";
import { conn } from "../../config/db.js";
export const router = express.Router();

router.post("/", async (req, res) => {
    const connection = await conn.getConnection();  
    try {
        await connection.beginTransaction();

        const {
            tour_name, country_id, type, duration_day, price, video, 
            promotion, condition_detail, include_flight, pdf_file, status,
            tour_details
        } = req.body;

        const insertTourQuery = `
            INSERT INTO Tour (
                tour_name, country_id, type, duration_day, price, video, 
                promotion, condition_detail, include_flight, pdf_file, status
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `;
        const tourValues = [
            tour_name, country_id, type, duration_day, price, video, 
            promotion, condition_detail, include_flight, pdf_file, status
        ];

        const [tourResult] = await connection.query(insertTourQuery, tourValues);
        const newTourId = tourResult.insertId; 

        if (tour_details && tour_details.length > 0) {
            const insertDetailQuery = `
                INSERT INTO TourDetail (
                    tour_id, day_number, day_detail, location, 
                    travel, hotel, meal_detail, restaurant_detail
                ) VALUES ?
            `;
            
            const detailValues = tour_details.map(detail => [
                newTourId, 
                detail.day_number, 
                detail.day_detail, 
                detail.location, 
                detail.travel, 
                detail.hotel, 
                detail.meal_detail, 
                detail.restaurant_detail
            ]);

            await connection.query(insertDetailQuery, [detailValues]);
        }

        await connection.commit();
        res.status(201).json({ 
            message: "เพิ่มข้อมูลทัวร์สำเร็จ", 
            tour_id: newTourId 
        });

    } catch (error) {
        await connection.rollback();
        console.error("Add Tour Transaction Error:", error);
        res.status(500).json({ 
            message: "เกิดข้อผิดพลาดในการบันทึกข้อมูลทัวร์", 
            error: error.message 
        });
    } finally {
        connection.release();
    }
});