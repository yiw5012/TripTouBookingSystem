import { Component, OnInit, ChangeDetectorRef, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { ServerApi } from '../../server/server';

@Component({
  selector: 'app-manage-tour',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './manage-tour.html',
  styleUrl: './manage-tour.css'
})
export class ManageTour implements OnInit {

  private readonly api = inject(ServerApi);
  private readonly router = inject(Router);
  private readonly cdr = inject(ChangeDetectorRef);

  tours: any[] = [];

  loading = false;
  errorMessage = '';
  deleteConfirmOpen = false;
  pendingDeleteTourId: number | null = null;
  pendingDeleteTourName = '';

  // ==========================================================
  // INIT
  // ==========================================================

  ngOnInit(): void {

    console.log('====================================');
    console.log('ManageTour ngOnInit');
    console.log('====================================');

    this.loadTours();
  }

  // ==========================================================
  // LOAD TOURS
  // ==========================================================

  async loadTours(): Promise<void> {

  console.log('====================================');
  console.log('LOAD TOURS START');
  console.log('====================================');

  this.loading = true;
  this.errorMessage = '';

  // บอก Angular ให้ redraw หลังเปลี่ยน loading
  this.cdr.detectChanges();

  try {

    const result = await this.api.getData('manage-tour/list');

    console.log('MANAGE TOUR RESULT =', result);

    if (result?.statusCode === 200) {

      if (result?.body?.success === true) {

        this.tours = result.body.data ?? [];

        console.log('TOURS =', this.tours);

      } else {

        this.tours = [];

        this.errorMessage =
          result?.body?.message ??
          'ไม่สามารถโหลดข้อมูลทัวร์ได้';
      }

    } else {

      this.tours = [];

      this.errorMessage =
        result?.body?.message ??
        'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้';
    }

  } catch (error) {

    console.error('LOAD TOURS ERROR =', error);

    this.tours = [];

    this.errorMessage =
      'เกิดข้อผิดพลาดในการโหลดข้อมูลทัวร์';

  } finally {

    this.loading = false;

    console.log('LOAD TOURS END');
    console.log('loading =', this.loading);
    console.log('tours.length =', this.tours.length);

    // สำคัญมาก
    // บังคับให้ Angular นำข้อมูลที่เพิ่งโหลดมาแสดงทันที
    this.cdr.detectChanges();
  }
}

  // ==========================================================
  // ADD TOUR
  // ==========================================================

  addTour(): void {
    this.router.navigate(['/add-tour']);
  }

  // ==========================================================
  // EDIT TOUR
  // ==========================================================

  editTour(tourId: number): void {

    console.log('EDIT TOUR ID =', tourId);

    if (!tourId || Number.isNaN(Number(tourId))) {

      console.error('INVALID TOUR ID =', tourId);

      return;
    }

    this.router.navigate(['/edit-tour', Number(tourId)]);
  }

  // ==========================================================
  // DELETE TOUR
  // ==========================================================

  openDeleteTourDialog(tour: any): void {
    const tourId = Number(tour?.tour_id);

    if (!tourId || Number.isNaN(tourId)) {
      this.errorMessage = 'รหัสทัวร์ไม่ถูกต้อง';
      return;
    }

    this.pendingDeleteTourId = tourId;
    this.pendingDeleteTourName = String(tour?.tour_name ?? `#${tourId}`);
    this.deleteConfirmOpen = true;
  }

  cancelDeleteTour(): void {
    this.deleteConfirmOpen = false;
    this.pendingDeleteTourId = null;
    this.pendingDeleteTourName = '';
  }

  async confirmDeleteTour(): Promise<void> {
    if (this.pendingDeleteTourId === null) {
      this.cancelDeleteTour();
      return;
    }

    const tourId = this.pendingDeleteTourId;

    this.cancelDeleteTour();
    await this.deleteTour(tourId);
  }

  async deleteTour(tourId: number): Promise<void> {

    console.log('DELETE TOUR ID =', tourId);

    if (!tourId || Number.isNaN(Number(tourId))) {

      console.error('INVALID TOUR ID =', tourId);

      return;
    }

    try {

      const result =
        await this.api.deleteData(`manage-tour/${tourId}`);

      console.log('DELETE RESULT =', result);

      if (result?.statusCode === 200) {

        alert('ลบทัวร์เรียบร้อยแล้ว');

        await this.loadTours();

      } else {

        alert(
          result?.body?.message ??
          'ไม่สามารถลบทัวร์ได้'
        );
      }

    } catch (error) {

      console.error('DELETE TOUR ERROR =', error);

      alert('เกิดข้อผิดพลาดในการลบทัวร์');
    }
  }

  // ==========================================================
  // STATUS TEXT
  // ==========================================================

  getTourStatus(status: string): string {

    if (status === 'open') {
      return 'เปิดขาย';
    }

    if (status === 'closed') {
      return 'ปิดขาย';
    }

    return status;
  }

  // ==========================================================
  // STATUS CLASS
  // ==========================================================

  getStatusClass(status: string): string {

    if (status === 'open') {
      return 'text-success';
    }

    if (status === 'closed') {
      return 'text-danger';
    }

    return '';
  }

  manageRounds(tourId: number): void {
  this.router.navigate([
    '/manage-round',
    tourId,
  ]);
}
}