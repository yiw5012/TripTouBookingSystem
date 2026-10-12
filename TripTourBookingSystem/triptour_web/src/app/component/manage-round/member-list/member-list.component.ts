import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { ServerApi } from '../../../server/server';

@Component({
  selector: 'app-memberlist-roundtour',
  standalone: true,
  imports: [CommonModule, FormsModule, MatProgressSpinnerModule],
  templateUrl: './member-list.component.html',
  styleUrl: './member-list.component.css', 
})
export class MemberListComponent implements OnInit {
  private serverApi = inject(ServerApi);
  private cdr = inject(ChangeDetectorRef);
  private route = inject(ActivatedRoute);
  private router = inject(Router);

  rounds: any[] = [];
  selectedTab: 'all' | 'open' | 'closed' = 'all';
  isLoading = false;
  isDownloadingTourPdf = false;
  errorMessage = '';
  currentRoundId: string | null = null;

  selectedRound: any = null;
  selectedRoundPassengers: any[] = [];

  get filteredRounds(): any[] {
    return this.rounds.filter((r) => {
      if (this.selectedTab === 'open') return r.status === 'open';
      if (this.selectedTab === 'closed') return r.status !== 'open';
      return true;
    });
  }

  ngOnInit(): void {
    this.route.paramMap.subscribe((params) => {
      const roundId = params.get('roundId');

      if (!roundId) {
        this.errorMessage = 'ไม่พบรหัสรอบทัวร์';
        this.rounds = [];
        this.selectedRound = null;
        this.selectedRoundPassengers = [];
        this.cdr.detectChanges();
        return;
      }

      this.currentRoundId = roundId;
      void this.loadAllData(roundId);
    });
  }

  async loadAllData(roundId: string): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';

    try {
      const [roundRes, passengersRes] = await Promise.all([
        this.serverApi.getRoundById(roundId),
        this.serverApi.getConfirmedMembersByRound(roundId)
      ]);

      if (roundRes.statusCode === 200 && roundRes.body?.success) {
        const round = roundRes.body.data;
        this.rounds = round ? [round] : [];
        this.selectedRound = round ?? null;
      } else {
        this.rounds = [];
        this.selectedRound = null;
        this.errorMessage = roundRes.body?.message || 'เกิดข้อผิดพลาดในการโหลดข้อมูลรอบทัวร์';
      }

      if (passengersRes.statusCode === 200 && passengersRes.body?.success) {
        this.selectedRoundPassengers = Array.isArray(passengersRes.body.data)
          ? passengersRes.body.data
          : [];
      } else {
        this.selectedRoundPassengers = [];

        if (!this.errorMessage) {
          this.errorMessage = passengersRes.body?.message || 'เกิดข้อผิดพลาดในการโหลดรายชื่อผู้เดินทาง';
        }
      }
    } catch {
      this.errorMessage = 'ไม่สามารถติดต่อเซิร์ฟเวอร์ได้';
      this.rounds = [];
      this.selectedRound = null;
      this.selectedRoundPassengers = [];
    } finally {
      this.isLoading = false;
      this.cdr.detectChanges();
    }
  }

  viewRoundDetail(round: any): void {
    if (!round?.round_id) {
      return;
    }

    if (String(round.round_id) !== String(this.currentRoundId)) {
      this.router.navigate(['/memberlist-roundtour', round.round_id]);
      return;
    }

    this.selectedRound = round;
  }

  closeDetailView(): void {
    this.selectedRound = null;
    this.selectedRoundPassengers = [];

    if (this.currentRoundId && this.rounds[0]?.tour_id) {
      this.router.navigate(['/manage-round', this.rounds[0].tour_id]);
      return;
    }

    this.router.navigate(['/manage-tour']);
  }

  getConfirmedCount(roundId: any): number {
    if (String(roundId) === String(this.currentRoundId)) {
      return this.selectedRoundPassengers.length;
    }

    return 0;
  }

  async downloadTourPdf(round: any): Promise<void> {
    const pdfUrl = String(round?.pdf_file ?? '').trim();

    if (!pdfUrl) {
      alert('ไม่พบไฟล์ PDF ของโปรแกรมทัวร์');
      return;
    }

    this.isDownloadingTourPdf = true;

    try {
      const response = await fetch(pdfUrl, { mode: 'cors' });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      const blob = await response.blob();
      const blobUrl = URL.createObjectURL(blob);
      const link = document.createElement('a');
      const safeTourName = String(round?.tour_name || `tour-${round?.tour_id || 'program'}`)
        .trim()
        .replace(/[\\/:*?"<>|]+/g, '-')
        .replace(/\s+/g, '_');

      link.href = blobUrl;
      link.download = `${safeTourName}_round_${round?.round_id || 'detail'}.pdf`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      URL.revokeObjectURL(blobUrl);
    } catch (error) {
      console.error('Download tour PDF error:', error);
      window.open(pdfUrl, '_blank', 'noopener,noreferrer');
    } finally {
      this.isDownloadingTourPdf = false;
    }
  }

  exportRoundToPdf(round: any): void {
    if (!round || this.selectedRoundPassengers.length === 0) {
      alert('ไม่มีข้อมูลผู้เดินทางที่คอนเฟิร์มแล้วในรอบนี้');
      return;
    }

    const tourName = this.escapeHtml(round.tour_name || 'Tour Program');
    const route = this.escapeHtml(`${round.departure || '-'} → ${round.destination || '-'}`);
    const startDate = this.escapeHtml(this.formatDate(round.start_date));
    const endDate = this.escapeHtml(this.formatDate(round.end_date));
    const price = this.escapeHtml(this.getPrice(round.price));

    const passengerRows = this.selectedRoundPassengers
      .map((passenger: any, index: number) => `
        <tr>
          <td>${index + 1}</td>
          <td>#${this.escapeHtml(passenger.booking_id)}</td>
          <td>
            <strong>${this.escapeHtml(this.getPassengerName(passenger))}</strong><br />
            Member ID: ${this.escapeHtml(passenger.member_id)}<br />
            เลขบัตร: ${this.escapeHtml(passenger.number_id || '-')}
          </td>
          <td>
            อีเมล: ${this.escapeHtml(passenger.email || '-')}<br />
            โทร: ${this.escapeHtml(passenger.phone || '-')}
          </td>
          <td>
            เพศ: ${this.escapeHtml(this.getGenderLabel(passenger.gender))}<br />
            วันเกิด: ${this.escapeHtml(this.formatDate(passenger.birthday))}<br />
            อายุ: ${this.escapeHtml(this.getPassengerAge(passenger))}
          </td>
          <td>
            ${this.escapeHtml(this.getPassengerHealthSummary(passenger))}
          </td>
          <td>${this.escapeHtml(this.getPrice(passenger.total_price))}</td>
          <td>${this.escapeHtml(this.formatDate(passenger.booking_date))}</td>
          <td>Confirmed</td>
        </tr>
      `)
      .join('');

    const printableHtml = `
      <!DOCTYPE html>
      <html lang="th">
        <head>
          <meta charset="UTF-8" />
          <title>Round ${this.escapeHtml(round.round_id)} - ${tourName}</title>
          <style>
            body { font-family: Arial, sans-serif; color: #1f2937; padding: 32px; line-height: 1.5; }
            h1, h2, h3 { margin: 0 0 12px; }
            .header { margin-bottom: 24px; border-bottom: 2px solid #d1d5db; padding-bottom: 16px; }
            .meta-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 12px 24px; margin: 20px 0 28px; }
            .meta-item { border: 1px solid #e5e7eb; border-radius: 8px; padding: 12px 14px; background: #f9fafb; }
            .label { display: block; font-size: 12px; color: #6b7280; margin-bottom: 4px; }
            table { width: 100%; border-collapse: collapse; margin-top: 12px; }
            th, td { border: 1px solid #d1d5db; padding: 10px; text-align: left; font-size: 13px; }
            th { background: #f3f4f6; }
            .actions { margin-top: 28px; display: flex; gap: 12px; }
            .btn { padding: 10px 16px; border-radius: 8px; color: #ffffff; background: #2563eb; text-decoration: none; border: none; cursor: pointer; font-size: 14px; }
            @media print {
              .actions { display: none; }
              body { padding: 0; }
            }
          </style>
        </head>
        <body>
          <div class="header">
            <h1>${tourName}</h1>
            <h3>รายละเอียดรอบทัวร์และรายชื่อผู้เดินทางที่ยืนยันแล้ว</h3>
          </div>

          <div class="meta-grid">
            <div class="meta-item"><span class="label">Tour ID</span>#${this.escapeHtml(round.tour_id)}</div>
            <div class="meta-item"><span class="label">Round ID</span>#${this.escapeHtml(round.round_id)}</div>
            <div class="meta-item"><span class="label">เส้นทาง</span>${route}</div>
            <div class="meta-item"><span class="label">วันเดินทาง</span>${startDate} ถึง ${endDate}</div>
            <div class="meta-item"><span class="label">ราคา</span>${price}</div>
            <div class="meta-item"><span class="label">ผู้เดินทางที่ยืนยันแล้ว</span>${this.escapeHtml(this.selectedRoundPassengers.length)} คน</div>
          </div>

          <h3>รายชื่อผู้เดินทาง</h3>
          <table>
            <thead>
              <tr>
                <th>#</th>
                <th>Booking ID</th>
                <th>ข้อมูลสมาชิก</th>
                <th>ติดต่อ</th>
                <th>ข้อมูลส่วนตัว</th>
                <th>ข้อมูลสุขภาพ</th>
                <th>ยอดชำระ</th>
                <th>วันที่จอง</th>
                <th>สถานะ</th>
              </tr>
            </thead>
            <tbody>
              ${passengerRows}
            </tbody>
          </table>

          <div class="actions">
            <button class="btn" onclick="window.print()">บันทึกเป็น PDF / พิมพ์</button>
          </div>
        </body>
      </html>
    `;

    this.printHtmlDocument(printableHtml);
  }

  private printHtmlDocument(html: string): void {
    const iframe = document.createElement('iframe');

    iframe.style.position = 'fixed';
    iframe.style.right = '0';
    iframe.style.bottom = '0';
    iframe.style.width = '0';
    iframe.style.height = '0';
    iframe.style.border = '0';

    document.body.appendChild(iframe);

    const iframeWindow = iframe.contentWindow;

    if (!iframeWindow) {
      document.body.removeChild(iframe);
      alert('ไม่สามารถเตรียมเอกสารสำหรับพิมพ์ได้');
      return;
    }

    iframeWindow.document.open();
    iframeWindow.document.write(html);
    iframeWindow.document.close();

    const cleanup = () => {
      window.setTimeout(() => {
        if (iframe.parentNode) {
          iframe.parentNode.removeChild(iframe);
        }
      }, 1000);
    };

    iframe.onload = () => {
      iframeWindow.focus();
      iframeWindow.print();
      cleanup();
    };
  }

  private escapeHtml(value: unknown): string {
    return String(value ?? '-')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  getPassengerName(passenger: any): string {
    return passenger?.display_name || passenger?.displayName || [passenger?.first_name, passenger?.last_name].filter(Boolean).join(' ') || '-';
  }

  getPassengerAge(passenger: any): string {
    const birthday = passenger?.birthday;

    if (!birthday) {
      return '-';
    }

    const birthDate = new Date(birthday);

    if (Number.isNaN(birthDate.getTime())) {
      return '-';
    }

    const today = new Date();
    let age = today.getFullYear() - birthDate.getFullYear();
    const monthDiff = today.getMonth() - birthDate.getMonth();

    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthDate.getDate())) {
      age -= 1;
    }

    return age >= 0 ? `${age} ปี` : '-';
  }

  getGenderLabel(gender: any): string {
    const normalizedGender = String(gender ?? '').trim().toLowerCase();

    if (normalizedGender === 'male') return 'ชาย';
    if (normalizedGender === 'female') return 'หญิง';
    if (normalizedGender === 'other') return 'อื่น ๆ';

    return gender || '-';
  }

  getPassengerHealthSummary(passenger: any): string {
    const parts = [
      passenger?.congenital_disease ? `โรคประจำตัว: ${passenger.congenital_disease}` : '',
      passenger?.medicine ? `ยา: ${passenger.medicine}` : '',
      passenger?.allergic_list ? `แพ้: ${passenger.allergic_list}` : '',
      passenger?.others ? `อื่น ๆ: ${passenger.others}` : '',
    ].filter(Boolean);

    return parts.length ? parts.join(' | ') : '-';
  }

  formatDate(dateStr: any): string {
    if (!dateStr) return '-';
    return String(dateStr).substring(0, 10);
  }

  getPrice(val: any): string {
    if (!val) return '0 ฿';
    return Number(val).toLocaleString() + ' ฿';
  }
}