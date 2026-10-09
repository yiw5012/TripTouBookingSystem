import { Component, OnInit, inject, ChangeDetectorRef } from '@angular/core'; // 1. เพิ่ม ChangeDetectorRef
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MatCardModule } from '@angular/material/card';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';

import { ServerApi } from '../../server/server';
import { DashboardData, DashboardResponse } from '../../model/dashborad.model';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    MatButtonModule,
    MatCardModule,
    MatIconModule,
    MatProgressSpinnerModule
  ],
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.css'
})
export class DashboardComponent implements OnInit {
  private serverApi = inject(ServerApi);
  private cdr = inject(ChangeDetectorRef); 
  rangeType = 'year';
  startDate = '';
  endDate = '';
  dashboardData?: DashboardData;
  isLoading = false;
  errorMessage = '';

  async ngOnInit(): Promise<void> {
    this.setAllRange();
    await this.loadAllData();
  }

  async loadAllData(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    this.cdr.detectChanges(); 

    try {
      const params = {
        startDate: this.startDate || '',
        endDate: this.endDate || '',
        rangeType: this.rangeType
      };

      const result = await this.serverApi.getDashboardData('/dashboard/overview', params);

      if (result.statusCode === 200 && result.body) {
        const bodyData = result.body.data || result.body;
        this.dashboardData = bodyData.data || bodyData;

        console.log('Dashboard Data:', this.dashboardData);
      } else {
        this.errorMessage = result.body?.message || 'เกิดข้อผิดพลาดในการโหลดข้อมูล';
      }
    } catch (error) {
      console.error('API Error:', error);
      this.errorMessage = 'ไม่สามารถติดต่อเซิร์ฟเวอร์ได้';
    } finally {
      this.isLoading = false;
      this.cdr.detectChanges(); // 4. บังคับให้ Angular สั่งวาด UI หน้าจอใหม่ทันที!
    }
  }

  

  async applyDateFilter(): Promise<void> {
    if (!this.startDate && !this.endDate) {
      this.setAllRange();
    }

    await this.loadAllData();
  }

  setRangeType(type: string): void {
    this.rangeType = type;

    if (type === 'year') {
      this.setAllRange();
    } else if (type === 'month') {
      this.setThisMonth();
    } else {
      this.setToday();
    }
  }

  setAllRange(): void {
    this.rangeType = 'year';
    this.startDate = '';
    this.endDate = '';
  }

  setThisYear(): void {
    this.setAllRange();
  }

  setThisMonth(): void {
    const now = new Date();
    const firstDay = new Date(now.getFullYear(), now.getMonth(), 1);
    const lastDay = new Date(now.getFullYear(), now.getMonth() + 1, 0);

    this.rangeType = 'month';
    this.startDate = this.toDateInputValue(firstDay);
    this.endDate = this.toDateInputValue(lastDay);
  }

  setToday(): void {
    const now = new Date();

    this.rangeType = 'day';
    this.startDate = this.toDateInputValue(now);
    this.endDate = this.toDateInputValue(now);
  }

  private toDateInputValue(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  exportReport(): void {
    if (!this.dashboardData) {
      alert('ไม่พบข้อมูลสำหรับ Export');
      return;
    }

    const summary = this.dashboardData.summary;
    const dateRangeText = (this.startDate && this.endDate) 
      ? `${this.startDate} ถึง ${this.endDate}` 
      : 'ทั้งหมด (All Time)';

    let csvContent = `รายงานภาพรวมระบบ (Dashboard Report)\n`;
    csvContent += `ช่วงวันที่,${dateRangeText}\n\n`;

    csvContent += `=== สรุปภาพรวม ===\n`;
    csvContent += `รายการ,จำนวน / มูลค่า\n`;
    csvContent += `รายรับรวม (บาท),${summary.totalIncome}\n`;
    csvContent += `จำนวนผู้ใช้ทั้งหมด (คน),${summary.totalUsers}\n`;
    csvContent += `จำนวนผู้ใช้เดินทาง (คน),${summary.toldTravelers}\n`;
    csvContent += `ยืนยันแล้ว (รายการ),${summary.confirmedUsers}\n`;
    csvContent += `จ่ายเงินแล้ว (รายการ),${summary.paidUsers}\n`;
    csvContent += `รอการยืนยัน (รายการ),${summary.pendingConfirmation}\n`;
    csvContent += `รอชำระเงิน (รายการ),${summary.pendingPayment}\n\n`;
    csvContent += `เดินทางเสร็จสิ้นแล้ว (รายการ),${summary.finishedUsers}\n\n`;


    csvContent += `=== รายได้ตามประเทศ ===\n`;
    csvContent += `ประเทศ,รายได้ (บาท)\n`;
    (this.dashboardData.revenueByCountry || []).forEach(item => {
      csvContent += `"${item.label}",${item.value}\n`;
    });
    csvContent += `\n`;


    csvContent += `=== ผู้ใช้เดินทางแยกตามประเทศ ===\n`;
    csvContent += `ประเทศ,จำนวนผู้ใช้ (คน)\n`;
    (this.dashboardData.usersByCountry || []).forEach(item => {
      csvContent += `"${item.label}",${item.value}\n`;
    });

    const blob = new Blob(['\uFEFF' + csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    
    const link = document.createElement('a');
    const todayStr = new Date().toISOString().split('T')[0];
    const fileName = `Dashboard_Report_${todayStr}.csv`;

    link.setAttribute('href', url);
    link.setAttribute('download', fileName);
    document.body.appendChild(link);
    link.click();
    
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
  }
}