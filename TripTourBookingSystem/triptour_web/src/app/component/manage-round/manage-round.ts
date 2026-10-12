import {
  ChangeDetectorRef,
  Component,
  OnInit,
} from '@angular/core';

import {
  FormBuilder,
  FormGroup,
  ReactiveFormsModule,
  Validators,
} from '@angular/forms';

import {
  ActivatedRoute,
  Router,
  RouterModule,
} from '@angular/router';

import { CommonModule } from '@angular/common';

import { ServerApi } from '../../server/server';

@Component({
  selector: 'app-manage-round',
  standalone: true,

  imports: [
    CommonModule,
    ReactiveFormsModule,
    RouterModule,
  ],

  templateUrl: './manage-round.html',
  styleUrl: './manage-round.css',
})
export class ManageRound implements OnInit {

  // ==========================================================
  // ข้อมูล Tour
  // ==========================================================

  tourId = 0;

  tour: any = null;

  get isFlightIncluded(): boolean {
  return String(
    this.tour?.include_flight ?? ''
  ).trim() === 'รวม';
}

  // ==========================================================
  // ข้อมูล Round
  // ==========================================================

  rounds: any[] = [];

  // ==========================================================
  // ข้อมูล Guide
  // ==========================================================

  guides: any[] = [];

  // ==========================================================
  // Form
  // ==========================================================

  form: FormGroup;

  // null = เพิ่มใหม่
  // มีค่า = กำลังแก้ไข
  editingRoundId: number | null = null;

  // ==========================================================
  // State
  // ==========================================================

  isLoading = true;

  isSaving = false;

  errorMessage = '';

  successMessage = '';

  // ==========================================================
  // Constructor
  // ==========================================================

  constructor(
    private fb: FormBuilder,
    private route: ActivatedRoute,
    private router: Router,
    private api: ServerApi,
    private cdr: ChangeDetectorRef
  ) {

    this.form = this.fb.group({

      departure: [
        '',
        Validators.required,
      ],

      destination: [
        '',
        Validators.required,
      ],

      start_date: [
        '',
        Validators.required,
      ],

      end_date: [
        '',
        Validators.required,
      ],

      airline: [
        '',
      ],

      flight: [
        '',
      ],

      flight_time: [
        '',
      ],

      price_single: [
        '',
        [
          Validators.required,
          Validators.min(0),
        ],
      ],

      price_double: [
        '',
        [
          Validators.required,
          Validators.min(0),
        ],
      ],

      price_triple: [
        '',
        [
          Validators.required,
          Validators.min(0),
        ],
      ],

      count: [
        '',
        [
          Validators.required,
          Validators.min(1),
        ],
      ],

      guide_id: [
        null,
      ],

      status: [
        'open',
        Validators.required,
      ],

    });
  }

  // ==========================================================
  // INIT
  // ==========================================================

  ngOnInit(): void {

    this.route.paramMap.subscribe((params) => {

      const id = Number(
        params.get('tourId')
      );

      if (
        !id ||
        Number.isNaN(id)
      ) {

        this.errorMessage =
          'tour_id ไม่ถูกต้อง';

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

  // ==========================================================
  // LOAD TOUR / ROUND / GUIDE
  // ==========================================================

  async loadData(): Promise<void> {

    this.isLoading = true;

    this.errorMessage = '';

    try {

      const result =
        await this.api.getData(
          `manage-round/tour/${this.tourId}`
        );

      if (
        result.statusCode === 200 &&
        result.body?.success === true
      ) {

        const data =
          result.body.data;

        this.tour =
          data.tour;

        this.rounds =
          data.rounds ?? [];

        this.guides =
          data.guides ?? [];

        this.isLoading = false;

        this.cdr.detectChanges();

        return;
      }

      this.errorMessage =
        result.body?.message ??
        'ไม่สามารถโหลดข้อมูลรอบทัวร์ได้';

      this.isLoading = false;

      this.cdr.detectChanges();

    } catch (error) {

      console.error(
        'Load Manage Round Error:',
        error
      );

      this.errorMessage =
        'เกิดข้อผิดพลาดในการโหลดข้อมูล';

      this.isLoading = false;

      this.cdr.detectChanges();
    }
  }

  // ==========================================================
  // START CREATE
  // ==========================================================

  startCreate(): void {

    this.editingRoundId = null;

    this.form.reset({

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

  // ==========================================================
  // EDIT
  // ==========================================================

  editRound(round: any): void {

    this.editingRoundId =
      Number(round.round_id);

    this.errorMessage = '';

    this.successMessage = '';

    this.form.patchValue({

      departure:
        round.departure ?? '',

      destination:
        round.destination ?? '',

      start_date:
        this.toDateInput(
          round.start_date
        ),

      end_date:
        this.toDateInput(
          round.end_date
        ),

      airline:
  this.isFlightIncluded
    ? round.airline ?? ''
    : '',

flight:
  this.isFlightIncluded
    ? round.flight ?? ''
    : '',

flight_time:
  this.isFlightIncluded
    ? this.toTimeInput(round.flight_time)
    : '',

      price_single:
        round.price_single ?? '',

      price_double:
        round.price_double ?? '',

      price_triple:
        round.price_triple ?? '',

      count:
        round.count ?? '',

      guide_id:
        round.guide_id
          ? Number(round.guide_id)
          : null,

status:
  ['open', 'closed', 'success'].includes(round.status)
    ? round.status
    : 'open',

    });

    window.scrollTo({
      top: 0,
      behavior: 'smooth',
    });
  }

  // ==========================================================
  // CANCEL EDIT
  // ==========================================================

  cancelEdit(): void {
    this.startCreate();
  }

  // ==========================================================
  // SAVE
  // ==========================================================

  async onSubmit(): Promise<void> {

    this.errorMessage = '';

    this.successMessage = '';

    this.form.markAllAsTouched();

    if (this.form.invalid) {

      this.errorMessage =
        'กรุณากรอกข้อมูลให้ครบถ้วน';

      return;
    }

    const value =
      this.form.getRawValue();

    // ========================================================
    // ตรวจวันที่
    // ========================================================

    const startDate =
      new Date(value.start_date);

    const endDate =
      new Date(value.end_date);

    if (
      startDate.getTime() >
      endDate.getTime()
    ) {

      this.errorMessage =
        'วันเริ่มทัวร์ต้องไม่มากกว่าวันสิ้นสุด';

      return;
    }

    this.isSaving = true;

    try {

      const payload = {

        tour_id:
          this.tourId,

        departure:
          String(
            value.departure
          ).trim(),

        destination:
          String(
            value.destination
          ).trim(),

        start_date:
          value.start_date,

        end_date:
          value.end_date,

        airline: this.isFlightIncluded
  ? String(value.airline ?? '').trim()
  : '',

flight: this.isFlightIncluded
  ? String(value.flight ?? '').trim()
  : '',

flight_time: this.isFlightIncluded
  ? String(value.flight_time ?? '').trim()
  : '',

        price_single:
          Number(
            value.price_single
          ),

        price_double:
          Number(
            value.price_double
          ),

        price_triple:
          Number(
            value.price_triple
          ),

        count:
          Number(
            value.count
          ),

        guide_id:
          value.guide_id
            ? Number(value.guide_id)
            : null,

        status:
          value.status,

      };

      let result: any;

      // ========================================================
      // UPDATE
      // ========================================================

      if (
        this.editingRoundId !== null
      ) {

        result =
          await this.api.putData(
            `manage-round/${this.editingRoundId}`,
            payload
          );

      }

      // ========================================================
      // CREATE
      // ========================================================

      else {

        result =
          await this.api.postData(
            'manage-round',
            payload
          );

      }

      // ========================================================
      // SUCCESS
      // ========================================================

      if (
        (
          result.statusCode === 200 ||
          result.statusCode === 201
        ) &&
        result.body?.success === true
      ) {

        this.successMessage =
          result.body.message ??
          'บันทึกข้อมูลสำเร็จ';

        const warning =
          result.body.data
            ?.guide_chat_warning;

        if (warning) {

          this.successMessage +=
            ` ${warning}`;

        }

        this.isSaving = false;

        this.startCreate();

        await this.loadData();

        this.cdr.detectChanges();

        return;
      }

      // ========================================================
      // ERROR FROM BACKEND
      // ========================================================

      this.errorMessage =
        result.body?.message ??
        'ไม่สามารถบันทึกข้อมูลได้';

      this.isSaving = false;

      this.cdr.detectChanges();

    } catch (error) {

      console.error(
        'Save Round Error:',
        error
      );

      this.errorMessage =
        'เกิดข้อผิดพลาดในการบันทึกข้อมูล';

      this.isSaving = false;

      this.cdr.detectChanges();
    }
  }

  // ==========================================================
  // DELETE
  // ==========================================================

  async deleteRound(
    roundId: number
  ): Promise<void> {

    const confirmed =
      window.confirm(
        `ต้องการลบรอบทัวร์ ${roundId} ใช่หรือไม่?`
      );

    if (!confirmed) {
      return;
    }

    try {

      const result =
        await this.api.deleteData(
          `manage-round/${roundId}`
        );

      if (
        result.statusCode === 200 &&
        result.body?.success === true
      ) {

        this.successMessage =
          result.body.message ??
          'ลบรอบทัวร์สำเร็จ';

        await this.loadData();

        this.cdr.detectChanges();

        return;
      }

      this.errorMessage =
        result.body?.message ??
        'ไม่สามารถลบรอบทัวร์ได้';

      this.cdr.detectChanges();

    } catch (error) {

      console.error(
        'Delete Round Error:',
        error
      );

      this.errorMessage =
        'เกิดข้อผิดพลาดในการลบรอบทัวร์';

      this.cdr.detectChanges();
    }
  }

  // ==========================================================
  // BACK TO MANAGE TOUR
  // ==========================================================

  goBack(): void {

    this.router.navigate([
      '/manage-tour',
    ]);

  }

  // ==========================================================
  // DATE
  // ==========================================================

  toDateInput(
    value: any
  ): string {

    if (!value) {
      return '';
    }

    return String(value)
      .substring(0, 10);
  }

  // ==========================================================
  // TIME
  // ==========================================================

  toTimeInput(
    value: any
  ): string {

    if (!value) {
      return '';
    }

    return String(value)
      .substring(0, 5);
  }

  // ==========================================================
  // GUIDE NAME
  // ==========================================================

  getGuideName(
    round: any
  ): string {

    const first =
      round.guide_first_name ?? '';

    const last =
      round.guide_last_name ?? '';

    const name =
      `${first} ${last}`.trim();

    if (name) {
      return name;
    }

    return 'ยังไม่กำหนดไกด์';
  }
}