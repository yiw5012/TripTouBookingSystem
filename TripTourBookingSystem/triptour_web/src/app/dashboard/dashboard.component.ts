import { Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { MatCardModule } from '@angular/material/card';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { MatListModule } from '@angular/material/list';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [FormsModule, MatCardModule, MatIconModule, MatButtonModule, MatListModule],
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.css'
})
export class DashboardComponent implements OnInit {
  startDate = '2026-10-01';
  endDate = '2026-10-31';

  ngOnInit(): void {
    this.loadAllData();
  }

  loadAllData(): void {
    // this.fetchIncome();
    // this.fetchTour();
    // this.fetchActiveTours();
    // this.fetchDataBookings();
    // this.fetchDataCountCountry();
  }

  applyDateFilter(): void {
    console.log('Selected range:', this.startDate, this.endDate);
  }

  setThisMonth(): void {
    const now = new Date();
    const firstDay = new Date(now.getFullYear(), now.getMonth(), 1);
    const lastDay = new Date(now.getFullYear(), now.getMonth() + 1, 0);

    this.startDate = this.toDateInputValue(firstDay);
    this.endDate = this.toDateInputValue(lastDay);
  }

  private toDateInputValue(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }
}