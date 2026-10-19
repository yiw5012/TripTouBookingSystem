import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../environments/environment.development';

interface BookingItem {
  booking_id: number;
  member_id: number;
  round_id: number;
  booking_date: string;
  total_price: string | number;
  status: string;
  payment_status: string;
  payment_date: string | null;
  slip_image: string | null;
  tour_id: number | null;
  tour_name: string | null;
  start_date: string | null;
  end_date: string | null;
  departure: string | null;
  destination: string | null;
  airline: string | null;
  flight: string | null;
}

@Component({
  selector: 'app-booking-approval',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './booking-approval.html',
  styleUrl: './booking-approval.css',
})
export class BookingApproval {
  // API
  private readonly baseUrl = 'https://triptoubookingsystem-production.up.railway.app';

  // DATA
  allBookings: BookingItem[] = [];
  filteredBookings: BookingItem[] = [];

  // SEARCH / FILTER
  searchText = '';
  paymentFilter = 'all';

  // PAGINATION
  currentPage = 1;
  pageSize = 10;

  // STATE
  isLoading = false;
  verifyingBookingId: number | null = null;
  errorMessage = '';
  successMessage = '';

  // SLIP MODAL
  isSlipModalOpen = false;
  selectedSlipUrl = '';

  constructor(
    private http: HttpClient,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.loadAllBookings();
  }

  // โหลดรายการจองทั้งหมด
  loadAllBookings(): void {
    this.isLoading = true;
    this.errorMessage = '';

    const url = `${this.baseUrl}/api/booking/admin/all-bookings`;
    console.log('====================================');
    console.log('LOAD ALL BOOKINGS');
    console.log('URL =', url);
    console.log('====================================');

    this.http.get<any>(url).subscribe({
      next: (response) => {
        console.log('ALL BOOKINGS RESPONSE =', response);

        if (response?.success === true) {
          this.allBookings = Array.isArray(response.data) ? response.data : [];
          this.currentPage = 1;
          this.applyFilters();
        } else {
          this.errorMessage = response?.message ?? 'ไม่สามารถโหลดข้อมูลการจองได้';
        }

        this.isLoading = false;
        this.cdr.detectChanges();
      },
      error: (error) => {
        console.error('LOAD ALL BOOKINGS ERROR =', error);
        this.isLoading = false;

        if (error?.status === 0) {
          this.errorMessage = 'ไม่สามารถเชื่อมต่อ Backend ได้';
        } else {
          this.errorMessage = error?.error?.message ?? `โหลดข้อมูลไม่สำเร็จ (HTTP ${error.status})`;
        }

        this.cdr.detectChanges();
      }
    });
  }

  // ค้นหาและกรองรายการจอง
  applyFilters(): void {
    const keyword = this.searchText.trim().toLowerCase();

    this.filteredBookings = this.allBookings.filter((booking) => {
      const searchableText = [
        booking.booking_id,
        booking.member_id,
        booking.round_id,
        booking.tour_id,
        booking.tour_name,
        booking.departure,
        booking.destination
      ]
        .filter(value => value !== null && value !== undefined)
        .join(' ')
        .toLowerCase();

      const matchesSearch = keyword === '' || searchableText.includes(keyword);
      let matchesPayment = false;

      if (this.paymentFilter === 'all') {
        matchesPayment = true;
      } else if (this.paymentFilter === 'review') {
        // ส่งสลิปแล้ว แต่แอดมินยังไม่ได้อนุมัติ
        matchesPayment =
          booking.payment_status === 'paid' &&
          booking.status === 'pending';
      } else if (this.paymentFilter === 'paid') {
        // แอดมินอนุมัติแล้ว
        matchesPayment =
          booking.payment_status === 'paid' &&
          booking.status === 'confirmed';
      } else {
        matchesPayment = booking.payment_status === this.paymentFilter;
      }

      return matchesSearch && matchesPayment;
    });

    this.currentPage = 1;
  }

  clearSearch(): void {
    this.searchText = '';
    this.applyFilters();
  }

  // PAGINATION
  get totalPages(): number {
    return Math.max(1, Math.ceil(this.filteredBookings.length / this.pageSize));
  }

  get pagedBookings(): BookingItem[] {
    const start = (this.currentPage - 1) * this.pageSize;
    const end = start + this.pageSize;
    return this.filteredBookings.slice(start, end);
  }

  goToPage(page: number): void {
    if (page < 1 || page > this.totalPages) return;
    this.currentPage = page;
  }

  nextPage(): void {
    if (this.currentPage < this.totalPages) this.currentPage++;
  }

  previousPage(): void {
    if (this.currentPage > 1) this.currentPage--;
  }

  // STATS
  get totalCount(): number {
    return this.allBookings.length;
  }

  // ส่งสลิปแล้ว รอแอดมินตรวจสอบ
  get reviewCount(): number {
    return this.allBookings.filter(
      booking => booking.payment_status === 'paid' && booking.status === 'pending'
    ).length;
  }

  // แอดมินอนุมัติแล้ว
  get paidCount(): number {
    return this.allBookings.filter(
      booking => booking.payment_status === 'paid' && booking.status === 'confirmed'
    ).length;
  }

  get cancelledCount(): number {
    return this.allBookings.filter(
      booking => booking.payment_status === 'cancelled'
    ).length;
  }

  get expiredCount(): number {
    return this.allBookings.filter(
      booking => booking.payment_status === 'expired'
    ).length;
  }

  // อนุมัติหรือปฏิเสธการจอง
  verifyBooking(bookingId: number, action: 'approve' | 'reject'): void {
    const actionText = action === 'approve' ? 'อนุมัติ' : 'ปฏิเสธ';
    const confirmed = window.confirm(`คุณต้องการ${actionText}รายการจอง #${bookingId} ใช่หรือไม่?`);
    if (!confirmed) return;

    this.verifyingBookingId = bookingId;
    this.errorMessage = '';
    this.successMessage = '';

    const url = `${this.baseUrl}/api/booking/admin/verify-slip`;
    const body = { booking_id: bookingId, action };

    this.http.post<any>(url, body).subscribe({
      next: (response) => {
        console.log('VERIFY RESPONSE =', response);

        if (response?.success === true) {
          this.successMessage = response?.message ?? `${actionText}รายการเรียบร้อยแล้ว`;
          this.loadAllBookings();
        } else {
          this.errorMessage = response?.message ?? `ไม่สามารถ${actionText}รายการได้`;
        }

        this.verifyingBookingId = null;
      },
      error: (error) => {
        console.error('VERIFY ERROR =', error);
        this.errorMessage = error?.error?.message ?? `เกิดข้อผิดพลาดในการ${actionText}รายการ`;
        this.verifyingBookingId = null;
        this.cdr.detectChanges();
      }
    });
  }

  // SLIP
  openSlipModal(url: string | null): void {
    if (!url) return;
    this.selectedSlipUrl = url;
    this.isSlipModalOpen = true;
  }

  closeSlipModal(): void {
    this.isSlipModalOpen = false;
    this.selectedSlipUrl = '';
  }

  // FORMAT PRICE
  getPrice(value: string | number): string {
    const numberValue = Number(value);
    if (Number.isNaN(numberValue)) return '0.00';

    return numberValue.toLocaleString('th-TH', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    });
  }

  // FORMAT DATE
  formatDate(value: string | null): string {
    if (!value) return '-';

    const date = new Date(value);
    if (Number.isNaN(date.getTime())) return '-';

    return date.toLocaleDateString('th-TH', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit'
    });
  }

  // PAYMENT STATUS TEXT
  paymentStatusText(status: string, bookingStatus: string): string {
    if (status === 'paid' && bookingStatus === 'pending') {
      return 'รอตรวจสอบ';
    }

    switch (status) {
      case 'paid':
        return 'ชำระแล้ว';
      case 'cancelled':
        return 'ยกเลิก';
      case 'expired':
        return 'หมดอายุ';
      case 'pending':
        return 'รอชำระ';
      default:
        return status;
    }
  }

  // BOOKING STATUS TEXT
  bookingStatusText(status: string): string {
    switch (status) {
      case 'confirmed':
        return 'ยืนยันแล้ว';
      case 'pending':
        return 'รอยืนยัน';
      case 'cancelled':
        return 'ยกเลิก';
      case 'reject':
        return 'ปฏิเสธ';
      case 'completed':
        return 'เสร็จสมบูรณ์';
      case 'finish':
        return 'เดินทางเสร็จแล้ว';
      default:
        return status;
    }
  }
}
