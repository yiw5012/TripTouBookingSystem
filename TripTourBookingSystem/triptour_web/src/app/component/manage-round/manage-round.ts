import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { ServerApi } from '../../server/server';

@Component({
  selector: 'app-manage-round',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterModule],
  templateUrl: './manage-round.html',
  styleUrl: './manage-round.css',
})
export class ManageRound implements OnInit {
  tourId = 0;
  tour: any = null;
  rounds: any[] = [];
  guides: any[] = [];
  form: FormGroup;
  editingRoundId: number | null = null;
  isLoading = true;
  isSaving = false;
  errorMessage = '';
  successMessage = '';
  finishingRoundId: number | null = null;

  get isFlightIncluded(): boolean {
    return String(this.tour?.include_flight ?? '').trim() === 'รวม';
  }

  constructor(
    private fb: FormBuilder,
    private route: ActivatedRoute,
    private router: Router,
    private api: ServerApi,
    private cdr: ChangeDetectorRef
  ) {
    this.form = this.fb.group({
      round_code: ['', [Validators.required, Validators.maxLength(50)]],
      departure: ['', Validators.required],
      destination: ['', Validators.required],
      start_date: ['', Validators.required],
      end_date: ['', Validators.required],
      airline: [''],
      flight: [''],
      flight_time: [''],
      price_single: ['', [Validators.required, Validators.min(0)]],
      price_double: ['', [Validators.required, Validators.min(0)]],
      price_triple: ['', [Validators.required, Validators.min(0)]],
      count: ['', [Validators.required, Validators.min(1)]],
      guide_id: [null],
      status: ['open', Validators.required],
    });
  }

  ngOnInit(): void {
    this.route.paramMap.subscribe((params) => {
      const id = Number(params.get('tourId'));

      if (!id || Number.isNaN(id)) {
        this.errorMessage = 'tour_id ไม่ถูกต้อง';
        this.isLoading = false;
        return;
      }

      this.tourId = id;
      this.loadData();
    });
  }

  viewRoundDetail(roundId: number | string): void {
    if (!roundId) return;
    this.router.navigate(['/memberlist-roundtour', roundId]);
  }

  async loadData(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';

    try {
      const result = await this.api.getData(`manage-round/tour/${this.tourId}`);

      if (result.statusCode === 200 && result.body?.success === true) {
        const data = result.body.data;
        this.tour = data.tour;
        this.rounds = data.rounds ?? [];
        this.guides = data.guides ?? [];
      } else {
        this.errorMessage = result.body?.message ?? 'ไม่สามารถโหลดข้อมูลรอบทัวร์ได้';
      }
    } catch (error) {
      console.error('Load Manage Round Error:', error);
      this.errorMessage = 'เกิดข้อผิดพลาดในการโหลดข้อมูล';
    } finally {
      this.isLoading = false;
      this.cdr.detectChanges();
    }
  }

  startCreate(): void {
    this.editingRoundId = null;
    this.errorMessage = '';
    this.successMessage = '';

    this.form.reset({
      round_code: '',
      departure: '',
      destination: '',
      start_date: '',
      end_date: '',
      airline: '',
      flight: '',
      flight_time: '',
      price_single: '',
      price_double: '',
      price_triple: '',
      count: '',
      guide_id: null,
      status: 'open',
    });
  }

  editRound(round: any): void {
    if (round.status === 'success') {
  this.errorMessage = 'รอบทัวร์นี้จบแล้ว ไม่สามารถแก้ไขข้อมูลได้';
  this.successMessage = '';
  return;
}
    this.editingRoundId = Number(round.round_id);
    this.errorMessage = '';
    this.successMessage = '';

    this.form.patchValue({
      round_code: round.round_code ?? '',
      departure: round.departure ?? '',
      destination: round.destination ?? '',
      start_date: this.toDateInput(round.start_date),
      end_date: this.toDateInput(round.end_date),
      airline: this.isFlightIncluded ? round.airline ?? '' : '',
      flight: this.isFlightIncluded ? round.flight ?? '' : '',
      flight_time: this.isFlightIncluded ? this.toTimeInput(round.flight_time) : '',
      price_single: round.price_single ?? '',
      price_double: round.price_double ?? '',
      price_triple: round.price_triple ?? '',
      count: round.count ?? '',
      guide_id: round.guide_id ? Number(round.guide_id) : null,
      status: ['open', 'closed', 'success'].includes(round.status) ? round.status : 'open',
    });

    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  cancelEdit(): void {
    this.startCreate();
  }

  async onSubmit(): Promise<void> {
    this.errorMessage = '';
    this.successMessage = '';
    this.form.markAllAsTouched();

    if (this.form.invalid) {
      this.errorMessage = 'กรุณากรอกข้อมูลให้ครบถ้วนและตรวจสอบรหัสรอบทัวร์';
      return;
    }

    const value = this.form.getRawValue();
    const normalizedRoundCode = String(value.round_code ?? '').trim().toUpperCase();

    if (!normalizedRoundCode) {
      this.errorMessage = 'กรุณากรอกรหัสรอบทัวร์';
      return;
    }

    if (normalizedRoundCode.length > 50) {
      this.errorMessage = 'รหัสรอบทัวร์ต้องไม่เกิน 50 ตัวอักษร';
      return;
    }

    const startDate = new Date(value.start_date);
    const endDate = new Date(value.end_date);

    if (startDate.getTime() > endDate.getTime()) {
      this.errorMessage = 'วันเริ่มทัวร์ต้องไม่มากกว่าวันสิ้นสุด';
      return;
    }

    this.isSaving = true;

    try {
      const payload = {
        tour_id: this.tourId,
        round_code: normalizedRoundCode,
        departure: String(value.departure ?? '').trim(),
        destination: String(value.destination ?? '').trim(),
        start_date: value.start_date,
        end_date: value.end_date,
        airline: this.isFlightIncluded ? String(value.airline ?? '').trim() : '',
        flight: this.isFlightIncluded ? String(value.flight ?? '').trim() : '',
        flight_time: this.isFlightIncluded ? String(value.flight_time ?? '').trim() : '',
        price_single: Number(value.price_single),
        price_double: Number(value.price_double),
        price_triple: Number(value.price_triple),
        count: Number(value.count),
        guide_id: value.guide_id ? Number(value.guide_id) : null,
        status: value.status,
      };

      let result: any;

      if (this.editingRoundId !== null) {
        result = await this.api.putData(
          `manage-round/${this.editingRoundId}`,
          payload
        );
      } else {
        result = await this.api.postData('manage-round', payload);
      }

      if (
        (result.statusCode === 200 || result.statusCode === 201) &&
        result.body?.success === true
      ) {
        this.successMessage = result.body.message ?? 'บันทึกข้อมูลสำเร็จ';

        const warning = result.body.data?.guide_chat_warning;
        if (warning) {
          this.successMessage += ` ${warning}`;
        }

        const message = this.successMessage;
        this.isSaving = false;
        this.startCreate();
        await this.loadData();
        this.cdr.detectChanges();
        alert(message);
        return;
      }

      this.errorMessage = result.body?.message ?? 'ไม่สามารถบันทึกข้อมูลได้';
    } catch (error: any) {
      console.error('Save Round Error:', error);
      this.errorMessage = error?.error?.message ?? 'เกิดข้อผิดพลาดในการบันทึกข้อมูล';
    } finally {
      this.isSaving = false;
      this.cdr.detectChanges();
    }
  }

  async deleteRound(roundId: number): Promise<void> {
    const round = this.rounds.find((item) => Number(item.round_id) === Number(roundId));
    const roundCode = round?.round_code || roundId;
    const confirmed = window.confirm(`ต้องการลบรอบทัวร์ ${roundCode} ใช่หรือไม่?`);

    if (!confirmed) return;

    try {
      const result = await this.api.deleteData(`manage-round/${roundId}`);

      if (result.statusCode === 200 && result.body?.success === true) {
        this.successMessage = result.body.message ?? 'ลบรอบทัวร์สำเร็จ';
        await this.loadData();
        this.cdr.detectChanges();
        return;
      }

      this.errorMessage = result.body?.message ?? 'ไม่สามารถลบรอบทัวร์ได้';
      this.cdr.detectChanges();
    } catch (error) {
      console.error('Delete Round Error:', error);
      this.errorMessage = 'เกิดข้อผิดพลาดในการลบรอบทัวร์';
      this.cdr.detectChanges();
    }
  }

  async finishRound(round: any): Promise<void> {
  const roundId = Number(round.round_id);

  if (!roundId || Number.isNaN(roundId)) {
    this.errorMessage = 'round_id ไม่ถูกต้อง';
    return;
  }

  const isRetry = round.status === 'success';

  const confirmMessage = isRetry
    ? `ต้องการลองลบห้องแชทของรอบ ${roundId} อีกครั้งใช่หรือไม่?`
    : `ยืนยันจบทัวร์รอบ ${roundId} ใช่หรือไม่?\n\nระบบจะเปลี่ยนสถานะ Booking ที่ชำระเงินและได้รับการอนุมัติแล้วเป็น "เดินทางเสร็จแล้ว" และลบห้องแชทของรอบนี้`;

  if (!window.confirm(confirmMessage)) {
    return;
  }

  this.finishingRoundId = roundId;
  this.errorMessage = '';
  this.successMessage = '';

  let nextSuccessMessage = '';
  let nextErrorMessage = '';
  let shouldReload = false;

  try {
    const result = await this.api.postData(
      `manage-round/${roundId}/finish`,
      {}
    );

    if (
      result.statusCode === 200 &&
      result.body?.success === true
    ) {
      nextSuccessMessage =
        result.body.message ?? 'จบทัวร์เรียบร้อยแล้ว';

      shouldReload = true;
    } else if (result.body?.tour_finished === true) {
      // MySQL จบทัวร์แล้ว แต่ Firebase อาจยังลบไม่สำเร็จ
      nextErrorMessage =
        result.body.message ??
        'บันทึกจบทัวร์แล้ว แต่ลบห้องแชทไม่สำเร็จ กรุณาลองอีกครั้ง';

      shouldReload = true;
    } else {
      nextErrorMessage =
        result.body?.message ?? 'ไม่สามารถจบทัวร์ได้';
    }

    // โหลดสถานะล่าสุดก่อน เพื่อให้ตารางแสดงข้อมูลใหม่
    // จากนั้นค่อยแสดงข้อความ ไม่ให้ loadData() ล้างข้อความแจ้งเตือน
    if (shouldReload) {
      await this.loadData();
    }

    this.successMessage = nextSuccessMessage;
    this.errorMessage = nextErrorMessage;
  } catch (error) {
    console.error('Finish Round Error:', error);

    nextErrorMessage =
      'เกิดข้อผิดพลาดในการจบทัวร์ กรุณาตรวจสอบสถานะรอบอีกครั้ง';

    await this.loadData();

    this.errorMessage = nextErrorMessage;
  } finally {
    this.finishingRoundId = null;
    this.cdr.detectChanges();
  }
}

isFinishingRound(roundId: number | string): boolean {
  return this.finishingRoundId === Number(roundId);
}

  goBack(): void {
    this.router.navigate(['/manage-tour']);
  }

  toDateInput(value: any): string {
    if (!value) return '';
    return String(value).substring(0, 10);
  }

  toTimeInput(value: any): string {
    if (!value) return '';
    return String(value).substring(0, 5);
  }

  getGuideName(round: any): string {
    const first = round.guide_first_name ?? '';
    const last = round.guide_last_name ?? '';
    const name = `${first} ${last}`.trim();
    return name || 'ยังไม่กำหนดไกด์';
  }
}