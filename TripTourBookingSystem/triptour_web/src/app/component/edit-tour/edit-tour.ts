import {
  Component,
  OnInit,
  ChangeDetectorRef,
  inject,
} from '@angular/core';

import { CommonModule } from '@angular/common';

import {
  ReactiveFormsModule,
  FormBuilder,
  FormGroup,
  FormArray,
  Validators,
} from '@angular/forms';

import {
  ActivatedRoute,
  Router,
} from '@angular/router';

import { ServerApi } from '../../server/server';

@Component({
  selector: 'app-edit-tour',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
  ],
  templateUrl: './edit-tour.html',
  styleUrl: './edit-tour.css',
})
export class EditTour implements OnInit {

  private readonly fb = inject(FormBuilder);
  private readonly api = inject(ServerApi);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly cdr = inject(ChangeDetectorRef);

  // ==========================================================
  // DATA
  // ==========================================================

  tourId = 0;

  tour: any = null;

  countries: any[] = [];

  existingImages: any[] = [];

  rounds: any[] = [];

  selectedImages: File[] = [];

  selectedImagePreviews: string[] = [];

  selectedVideo: File | null = null;

  selectedPdf: File | null = null;

  loading = false;

  isSubmitting = false;

  errorMessage = '';

  successMessage = '';

  tourForm!: FormGroup;

  number(value: any): number {
  return Number(value);
}

  // ==========================================================
  // INIT
  // ==========================================================

  ngOnInit(): void {

    const id = Number(
      this.route.snapshot.paramMap.get('tourId')
    );

    if (!id || isNaN(id)) {
      this.errorMessage = 'tour_id ไม่ถูกต้อง';
      return;
    }

    this.tourId = id;

    this.initForm();

    this.loadData();
  }

  // ==========================================================
  // INIT FORM
  // ==========================================================

  initForm(): void {

    this.tourForm = this.fb.group({

      tour_name: [
        '',
        Validators.required,
      ],

      country_id: [
        null,
        Validators.required,
      ],

      type: [
        'ในประเทศ',
        Validators.required,
      ],

      duration_day: [
        1,
        [
          Validators.required,
          Validators.min(1),
        ],
      ],

      price: [
        0,
        [
          Validators.required,
          Validators.min(0),
        ],
      ],

      promotion: [
        '',
      ],

      condition_detail: [
        '',
      ],

      include_flight: [
        'ไม่รวม',
        Validators.required,
      ],

      status: [
        'open',
        Validators.required,
      ],

      tour_details: this.fb.array([]),
    });
  }

  // ==========================================================
  // GET TOUR DETAILS FORM ARRAY
  // ==========================================================

  get tourDetails(): FormArray {
    return this.tourForm.get(
      'tour_details'
    ) as FormArray;
  }

  // ==========================================================
  // CREATE DAY FORM
  // ==========================================================

  createDayForm(day: any = {}): FormGroup {

    return this.fb.group({

      day_number: [
        Number(day.day_number) || this.tourDetails.length + 1,
      ],

      day_detail: [
        day.day_detail || '',
      ],

      location: [
        day.location || '',
      ],

      travel: [
        day.travel || '',
      ],

      hotel: [
        day.hotel || '',
      ],

      meal_detail: [
        day.meal_detail || '',
      ],

      restaurant_detail: [
        day.restaurant_detail || '',
      ],
    });
  }

  // ==========================================================
  // ADD DAY
  // ==========================================================

  addDay(): void {

    const newDayNumber =
      this.tourDetails.length + 1;

    this.tourDetails.push(
      this.createDayForm({
        day_number: newDayNumber,
      })
    );

    this.renumberDays();
  }

  // ==========================================================
  // REMOVE DAY
  // ==========================================================

  removeDay(index: number): void {

    if (this.tourDetails.length <= 1) {
      return;
    }

    this.tourDetails.removeAt(index);

    this.renumberDays();

    this.tourForm
      .get('duration_day')
      ?.setValue(this.tourDetails.length);
  }

  // ==========================================================
  // RENUMBER DAYS
  // ==========================================================

  renumberDays(): void {

    this.tourDetails.controls.forEach(
      (control, index) => {

        control.get('day_number')
          ?.setValue(index + 1);
      }
    );
  }

  // ==========================================================
  // SYNC DETAIL WITH DURATION
  // ==========================================================

  syncDetailsToDuration(): void {

    const duration = Number(
      this.tourForm
        .get('duration_day')
        ?.value
    );

    if (
      !Number.isFinite(duration) ||
      duration < 1
    ) {
      return;
    }

    while (
      this.tourDetails.length < duration
    ) {
      this.addDay();
    }

    while (
      this.tourDetails.length > duration
    ) {
      this.tourDetails.removeAt(
        this.tourDetails.length - 1
      );
    }

    this.renumberDays();
  }

  // ==========================================================
  // LOAD DATA
  // ==========================================================

  async loadData(): Promise<void> {

    this.loading = true;

    this.errorMessage = '';

    this.successMessage = '';

    this.cdr.detectChanges();

    try {

      const [
        tourResult,
        countryResult,
      ] = await Promise.all([

        this.api.getData(
          `manage-tour/${this.tourId}`
        ),

        this.api.getData(
          'add-tour/search-options/countries'
        ),
      ]);

      // ========================================================
      // TOUR
      // ========================================================

      if (
        tourResult?.statusCode !== 200 ||
        tourResult?.body?.success !== true
      ) {

        this.errorMessage =
          tourResult?.body?.message ||
          'ไม่สามารถโหลดข้อมูลทัวร์ได้';

        return;
      }

      const data =
        tourResult.body.data;

      this.tour =
        data.tour;

      this.existingImages =
        data.images || [];

      this.rounds =
        data.rounds || [];

      const details =
        data.details || [];

      // ========================================================
      // COUNTRIES
      // ========================================================

      if (
        countryResult?.statusCode === 200 &&
        countryResult?.body?.success === true
      ) {

        this.countries =
          countryResult.body.data || [];

      } else {

        this.countries = [];
      }

      // ========================================================
      // PATCH FORM
      // ========================================================

      this.tourForm.patchValue({

        tour_name:
          this.tour.tour_name || '',

        country_id:
          Number(this.tour.country_id),

        type:
          this.normalizeType(
            this.tour.type
          ),

        duration_day:
          Number(this.tour.duration_day) || 1,

        price:
          Number(this.tour.price) || 0,

        promotion:
          this.tour.promotion || '',

        condition_detail:
          this.tour.condition_detail || '',

        include_flight:
          this.tour.include_flight ||
          'ไม่รวม',

        status:
          this.normalizeStatus(
            this.tour.status
          ),
      });

      // ========================================================
      // DETAILS
      // ========================================================

      this.tourDetails.clear();

      if (details.length > 0) {

        for (const detail of details) {

          this.tourDetails.push(
            this.createDayForm(detail)
          );
        }

      } else {

        this.addDay();
      }

      this.renumberDays();

    } catch (error) {

      console.error(
        'Load Edit Tour Error:',
        error
      );

      this.errorMessage =
        'ไม่สามารถเชื่อมต่อ Backend ได้';

    } finally {

      this.loading = false;

      this.cdr.detectChanges();
    }
  }

  // ==========================================================
  // NORMALIZE TYPE
  // ==========================================================

  normalizeType(type: any): string {

    if (type === 'ต่างประเทศ') {
      return 'นอกประเทศ';
    }

    if (
      type === 'นอกประเทศ'
    ) {
      return 'นอกประเทศ';
    }

    return 'ในประเทศ';
  }

  // ==========================================================
  // NORMALIZE STATUS
  // ==========================================================

  normalizeStatus(status: any): string {

    if (status === 'Active') {
      return 'open';
    }

    if (status === 'closed') {
      return 'closed';
    }

    return 'open';
  }

  // ==========================================================
  // SELECT IMAGES
  // ==========================================================

  onImagesSelected(
    event: Event
  ): void {

    const input =
      event.target as HTMLInputElement;

    const files =
      Array.from(input.files || []);

    const remainingSlots =
      20 -
      this.existingImages.length -
      this.selectedImages.length;

    if (remainingSlots <= 0) {

      alert(
        'สามารถมีรูปภาพได้สูงสุด 20 รูป'
      );

      input.value = '';

      return;
    }

    const validFiles =
      files
        .filter((file) =>
          file.type.startsWith('image/')
        )
        .slice(0, remainingSlots);

    for (const file of validFiles) {

      this.selectedImages.push(file);

      this.selectedImagePreviews.push(
        URL.createObjectURL(file)
      );
    }

    input.value = '';
  }

  // ==========================================================
  // REMOVE EXISTING IMAGE
  // ==========================================================

  removeExistingImage(
    index: number
  ): void {

    this.existingImages.splice(
      index,
      1
    );

    this.cdr.detectChanges();
  }

  // ==========================================================
  // REMOVE NEW IMAGE
  // ==========================================================

  removeSelectedImage(
    index: number
  ): void {

    const preview =
      this.selectedImagePreviews[index];

    if (preview) {
      URL.revokeObjectURL(preview);
    }

    this.selectedImagePreviews.splice(
      index,
      1
    );

    this.selectedImages.splice(
      index,
      1
    );
  }

  // ==========================================================
  // SELECT VIDEO
  // ==========================================================

  onVideoSelected(
    event: Event
  ): void {

    const input =
      event.target as HTMLInputElement;

    const file =
      input.files?.[0] || null;

    if (!file) {
      return;
    }

    if (!file.type.startsWith('video/')) {

      alert(
        'กรุณาเลือกไฟล์วิดีโอ'
      );

      input.value = '';

      return;
    }

    this.selectedVideo = file;

    input.value = '';
  }

  // ==========================================================
  // REMOVE SELECTED VIDEO
  // ==========================================================

  removeSelectedVideo(): void {

    this.selectedVideo = null;
  }

  // ==========================================================
  // SELECT PDF
  // ==========================================================

  onPdfSelected(
    event: Event
  ): void {

    const input =
      event.target as HTMLInputElement;

    const file =
      input.files?.[0] || null;

    if (!file) {
      return;
    }

    const isPdf =
      file.type === 'application/pdf' ||
      file.name
        .toLowerCase()
        .endsWith('.pdf');

    if (!isPdf) {

      alert(
        'กรุณาเลือกไฟล์ PDF เท่านั้น'
      );

      input.value = '';

      return;
    }

    this.selectedPdf = file;

    input.value = '';
  }

  // ==========================================================
  // REMOVE SELECTED PDF
  // ==========================================================

  removeSelectedPdf(): void {

    this.selectedPdf = null;
  }

  // ==========================================================
  // SUBMIT
  // ==========================================================

  async onSubmit(): Promise<void> {

    this.successMessage = '';

    this.errorMessage = '';

    if (
      this.tourForm.invalid
    ) {

      this.tourForm.markAllAsTouched();

      return;
    }

    this.isSubmitting = true;

    this.cdr.detectChanges();

    try {

      this.renumberDays();

      const formData =
        new FormData();

      // ========================================================
      // TOUR
      // ========================================================

      formData.append(
        'tour_name',
        this.tourForm.get('tour_name')?.value || ''
      );

      formData.append(
        'country_id',
        String(
          this.tourForm.get('country_id')?.value
        )
      );

      formData.append(
        'type',
        this.tourForm.get('type')?.value || 'ในประเทศ'
      );

      formData.append(
        'duration_day',
        String(
          this.tourForm.get('duration_day')?.value
        )
      );

      formData.append(
        'price',
        String(
          this.tourForm.get('price')?.value
        )
      );

      formData.append(
        'promotion',
        this.tourForm.get('promotion')?.value || ''
      );

      formData.append(
        'condition_detail',
        this.tourForm.get('condition_detail')?.value || ''
      );

      formData.append(
        'include_flight',
        this.tourForm.get('include_flight')?.value || 'ไม่รวม'
      );

      formData.append(
        'status',
        this.tourForm.get('status')?.value || 'open'
      );

      // ========================================================
      // DETAILS
      // ========================================================

      formData.append(
        'tour_details',
        JSON.stringify(
          this.tourDetails.value
        )
      );

      // ========================================================
      // EXISTING IMAGES
      // ========================================================

      formData.append(
        'keep_image_ids',
        JSON.stringify(
          this.existingImages
            .map(
              (image) =>
                Number(image.img_id)
            )
            .filter(
              (id) =>
                Number.isInteger(id) &&
                id > 0
            )
        )
      );

      // ========================================================
      // NEW IMAGES
      // ========================================================

      for (
        const file
        of this.selectedImages
      ) {

        formData.append(
          'tour_images',
          file
        );
      }

      // ========================================================
      // VIDEO
      // ========================================================

      if (this.selectedVideo) {

        formData.append(
          'video',
          this.selectedVideo
        );
      }

      // ========================================================
      // PDF
      // ========================================================

      if (this.selectedPdf) {

        formData.append(
          'pdf_file',
          this.selectedPdf
        );
      }

      // ========================================================
      // PUT
      // ========================================================

      const result =
        await this.api.putData(
          `manage-tour/${this.tourId}`,
          formData
        );

      console.log(
        'EDIT TOUR RESPONSE =',
        result
      );

      if (
        result?.statusCode === 200 &&
        result?.body?.success === true
      ) {

        this.successMessage =
          result.body.message ||
          'แก้ไขข้อมูลทัวร์สำเร็จ';

        // โหลดข้อมูลใหม่
        await this.loadData();

        window.scrollTo({
          top: 0,
          behavior: 'smooth',
        });

      } else {

        this.errorMessage =
          result?.body?.message ||
          'ไม่สามารถแก้ไขข้อมูลทัวร์ได้';
      }

    } catch (error) {

      console.error(
        'Submit Edit Tour Error:',
        error
      );

      this.errorMessage =
        'เกิดข้อผิดพลาดในการบันทึกข้อมูล';

    } finally {

      this.isSubmitting = false;

      this.cdr.detectChanges();
    }
  }

  // ==========================================================
  // BACK
  // ==========================================================

  back(): void {

    this.router.navigate([
      '/manage-tour'
    ]);
  }

  // ==========================================================
  // DESTROY
  // ==========================================================

  ngOnDestroy(): void {

    for (
      const preview
      of this.selectedImagePreviews
    ) {

      URL.revokeObjectURL(preview);
    }
  }
}