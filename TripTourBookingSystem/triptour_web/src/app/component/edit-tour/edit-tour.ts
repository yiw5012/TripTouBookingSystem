import {
  Component,
  OnInit,
  OnDestroy,
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
import { ActivatedRoute, Router } from '@angular/router';
import { ServerApi } from '../../server/server';

@Component({
  selector: 'app-edit-tour',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './edit-tour.html',
  styleUrl: './edit-tour.css',
})
export class EditTour implements OnInit, OnDestroy {
  private readonly fb = inject(FormBuilder);
  private readonly api = inject(ServerApi);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly cdr = inject(ChangeDetectorRef);

  // DATA
  tourId = 0;
  tour: any = null;
  countries: any[] = [];
  existingImages: any[] = [];
  rounds: any[] = [];
  selectedImages: File[] = [];
  selectedImagePreviews: string[] = [];
  selectedVideo: File | null = null;
  selectedPdf: File | null = null;

  // ลบไฟล์เดิม
  removeExistingVideo = false;
  removeExistingPdf = false;

  // CLOUDINARY
  cloudImages: any[] = [];
  selectedCloudImages: any[] = [];
  showCloudImagePicker = false;
  isLoadingCloudImages = false;
  cloudImagesError = '';
  cloudImagesNextCursor: string | null = null;
  hasLoadedCloudImages = false;

  // STATUS
  loading = false;
  isSubmitting = false;
  errorMessage = '';
  successMessage = '';

  readonly defaultConditionDetail =
    'เงื่อนไขการเดินทางและการให้บริการเป็นไปตามรายละเอียดโปรแกรมทัวร์ที่ระบุไว้ กรุณาตรวจสอบข้อมูลและเอกสารการเดินทางให้ครบถ้วนก่อนยืนยันการจอง';

  tourForm!: FormGroup;

  number(value: any): number {
    return Number(value);
  }

  // INIT
  ngOnInit(): void {
    const id = Number(this.route.snapshot.paramMap.get('tourId'));

    if (!id || Number.isNaN(id)) {
      this.errorMessage = 'tour_id ไม่ถูกต้อง';
      return;
    }

    this.tourId = id;
    this.initForm();
    this.loadData();
  }

  // INIT FORM
  initForm(): void {
    this.tourForm = this.fb.group({
      tour_name: ['', Validators.required],
      tour_code: ['', [Validators.required, Validators.maxLength(50)]],
      country_id: [null, Validators.required],
      type: ['ในประเทศ', Validators.required],
      duration_day: [1, [Validators.required, Validators.min(1)]],
      price: [0, [Validators.required, Validators.min(0)]],
      promotion: [''],
      condition_mode: ['default', Validators.required],
      condition_detail: [''],
      include_flight: ['ไม่รวม', Validators.required],
      status: ['open', Validators.required],
      tour_details: this.fb.array([]),
    });
  }

  // FORM ARRAY
  get tourDetails(): FormArray {
    return this.tourForm.get('tour_details') as FormArray;
  }

  // CREATE DAY
  createDayForm(day: any = {}): FormGroup {
    return this.fb.group({
      day_number: [
        Number(day.day_number) || this.tourDetails.length + 1,
      ],
      day_detail: [day.day_detail || ''],
      location: [day.location || ''],
      travel: [day.travel || ''],
      hotel: [day.hotel || ''],
      meal_detail: [day.meal_detail || ''],
      restaurant_detail: [day.restaurant_detail || ''],
    });
  }

  // ADD DAY
  addDay(): void {
    const newDayNumber = this.tourDetails.length + 1;

    this.tourDetails.push(
      this.createDayForm({ day_number: newDayNumber })
    );

    this.renumberDays();
  }

  // REMOVE DAY
  removeDay(index: number): void {
    if (this.tourDetails.length <= 1) {
      return;
    }

    this.tourDetails.removeAt(index);
    this.renumberDays();
    this.tourForm.get('duration_day')?.setValue(this.tourDetails.length);
  }

  // RENUMBER DAYS
  renumberDays(): void {
    this.tourDetails.controls.forEach((control, index) => {
      control.get('day_number')?.setValue(index + 1);
    });
  }

  // SYNC DETAILS WITH DURATION
  syncDetailsToDuration(): void {
    const duration = Number(this.tourForm.get('duration_day')?.value);

    if (!Number.isFinite(duration) || duration < 1) {
      return;
    }

    while (this.tourDetails.length < duration) {
      this.addDay();
    }

    while (this.tourDetails.length > duration) {
      this.tourDetails.removeAt(this.tourDetails.length - 1);
    }

    this.renumberDays();
  }

  // LOAD TOUR DATA
  async loadData(): Promise<void> {
    this.loading = true;
    this.errorMessage = '';
    this.successMessage = '';
    this.cdr.detectChanges();

    try {
      const [tourResult, countryResult] = await Promise.all([
        this.api.getData(`manage-tour/${this.tourId}`),
        this.api.getData('add-tour/countries'),
      ]);

      if (
        tourResult?.statusCode !== 200 ||
        tourResult?.body?.success !== true
      ) {
        this.errorMessage =
          tourResult?.body?.message ||
          'ไม่สามารถโหลดข้อมูลทัวร์ได้';
        return;
      }

      const data = tourResult.body.data;

      this.tour = data.tour;
      this.existingImages = data.images || [];
      this.rounds = data.rounds || [];

      const details = data.details || [];

      if (
        countryResult?.statusCode === 200 &&
        countryResult?.body?.success === true
      ) {
        this.countries = countryResult.body.data || [];
      } else {
        this.countries = [];
      }

      const currentCondition = String(
        this.tour.condition_detail ?? ''
      ).trim();

      const conditionMode =
        !currentCondition ||
        currentCondition === this.defaultConditionDetail
          ? 'default'
          : 'custom';

      this.tourForm.patchValue({
        tour_name: this.tour.tour_name || '',
        tour_code: this.tour.tour_code || '',
        country_id: Number(this.tour.country_id),
        type: this.normalizeType(this.tour.type),
        duration_day: Number(this.tour.duration_day) || 1,
        price: Number(this.tour.price) || 0,
        promotion: this.tour.promotion || '',
        condition_mode: conditionMode,
        condition_detail: currentCondition,
        include_flight: this.tour.include_flight || 'ไม่รวม',
        status: this.normalizeStatus(this.tour.status),
      });

      this.tourDetails.clear();

      if (details.length > 0) {
        for (const detail of details) {
          this.tourDetails.push(this.createDayForm(detail));
        }
      } else {
        this.addDay();
      }

      this.renumberDays();
    } catch (error) {
      console.error('Load Edit Tour Error:', error);
      this.errorMessage = 'ไม่สามารถเชื่อมต่อ Backend ได้';
    } finally {
      this.loading = false;
      this.cdr.detectChanges();
    }
  }

  // NORMALIZE TYPE
  normalizeType(type: any): string {
    if (type === 'ต่างประเทศ' || type === 'นอกประเทศ') {
      return 'นอกประเทศ';
    }
    return 'ในประเทศ';
  }

  // NORMALIZE STATUS
  normalizeStatus(status: any): string {
    if (status === 'Active') {
      return 'open';
    }
    if (status === 'closed') {
      return 'closed';
    }
    return 'open';
  }

  // SELECT IMAGES
  onImagesSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const files = Array.from(input.files || []);

    const remainingSlots =
      20 - this.existingImages.length - this.selectedImages.length;

    if (remainingSlots <= 0) {
      alert('สามารถมีรูปภาพได้สูงสุด 20 รูป');
      input.value = '';
      return;
    }

    const validFiles = files
      .filter((file) => file.type.startsWith('image/'))
      .slice(0, remainingSlots);

    for (const file of validFiles) {
      this.selectedImages.push(file);
      this.selectedImagePreviews.push(URL.createObjectURL(file));
    }

    input.value = '';
  }

  // REMOVE EXISTING IMAGE
  removeExistingImage(index: number): void {
    this.existingImages.splice(index, 1);
    this.cdr.detectChanges();
  }

  // REMOVE NEW IMAGE
  removeSelectedImage(index: number): void {
    const preview = this.selectedImagePreviews[index];

    if (preview) {
      URL.revokeObjectURL(preview);
    }

    this.selectedImagePreviews.splice(index, 1);
    this.selectedImages.splice(index, 1);
  }

  // SELECT VIDEO
  onVideoSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0] || null;

    if (!file) {
      return;
    }

    if (!file.type.startsWith('video/')) {
      alert('กรุณาเลือกไฟล์วิดีโอ');
      input.value = '';
      return;
    }

    this.selectedVideo = file;
    this.removeExistingVideo = false;
    input.value = '';
  }

  // REMOVE SELECTED VIDEO
  removeSelectedVideo(): void {
    this.selectedVideo = null;
  }

  // REMOVE EXISTING VIDEO
  removeExistingVideoFile(): void {
    this.removeExistingVideo = true;
    this.selectedVideo = null;
  }

  // UNDO REMOVE EXISTING VIDEO
  undoRemoveExistingVideo(): void {
    this.removeExistingVideo = false;
  }

  // SELECT PDF
  onPdfSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0] || null;

    if (!file) {
      return;
    }

    const isPdf =
      file.type === 'application/pdf' ||
      file.name.toLowerCase().endsWith('.pdf');

    if (!isPdf) {
      alert('กรุณาเลือกไฟล์ PDF เท่านั้น');
      input.value = '';
      return;
    }

    this.selectedPdf = file;
    this.removeExistingPdf = false;
    input.value = '';
  }

  // REMOVE SELECTED PDF
  removeSelectedPdf(): void {
    this.selectedPdf = null;
  }

  // REMOVE EXISTING PDF
  removeExistingPdfFile(): void {
    this.removeExistingPdf = true;
    this.selectedPdf = null;
  }

  // UNDO REMOVE EXISTING PDF
  undoRemoveExistingPdf(): void {
    this.removeExistingPdf = false;
  }

  // TOGGLE CLOUDINARY PICKER
  async toggleCloudImagePicker(): Promise<void> {
    this.showCloudImagePicker = !this.showCloudImagePicker;

    if (
      this.showCloudImagePicker &&
      !this.hasLoadedCloudImages
    ) {
      await this.loadCloudImages(true);
    }
  }

  // LOAD CLOUDINARY IMAGES
  async loadCloudImages(reset = false): Promise<void> {
    if (this.isLoadingCloudImages) {
      return;
    }

    const cursor = reset ? null : this.cloudImagesNextCursor;

    if (!reset && !cursor) {
      return;
    }

    this.isLoadingCloudImages = true;
    this.cloudImagesError = '';

    try {
      const endpoint = cursor
        ? `add-tour/cloud-images?next_cursor=${encodeURIComponent(cursor)}`
        : 'add-tour/cloud-images';

      const result = await this.api.getData(endpoint);

      if (
        result?.statusCode === 200 &&
        result?.body?.success === true
      ) {
        const receivedImages: any[] = result.body.data ?? [];

        if (reset) {
          this.cloudImages = receivedImages;
        } else {
          const existingIds = new Set(
            this.cloudImages.map((image) => image.public_id)
          );

          this.cloudImages = [
            ...this.cloudImages,
            ...receivedImages.filter(
              (image) => !existingIds.has(image.public_id)
            ),
          ];
        }

        this.cloudImagesNextCursor =
          result.body.next_cursor ?? null;
        this.hasLoadedCloudImages = true;
      } else {
        this.cloudImagesError =
          result?.body?.message ??
          'ไม่สามารถโหลดรูปจาก Cloudinary ได้';
      }
    } catch (error) {
      console.error('Load Cloudinary Images Error:', error);
      this.cloudImagesError =
        'เกิดข้อผิดพลาดในการโหลดรูปจาก Cloudinary';
    } finally {
      this.isLoadingCloudImages = false;
      this.cdr.detectChanges();
    }
  }

  // LOAD MORE CLOUDINARY IMAGES
  async loadMoreCloudImages(): Promise<void> {
    await this.loadCloudImages(false);
  }

  // TOGGLE CLOUDINARY IMAGE
  toggleCloudImage(image: any): void {
    const index = this.selectedCloudImages.findIndex(
      (item) => item.public_id === image.public_id
    );

    if (index >= 0) {
      this.selectedCloudImages.splice(index, 1);
    } else {
      this.selectedCloudImages.push(image);
    }

    this.selectedCloudImages = [...this.selectedCloudImages];
  }

  // CHECK CLOUDINARY IMAGE SELECTION
  isCloudImageSelected(publicId: string): boolean {
    return this.selectedCloudImages.some(
      (image) => image.public_id === publicId
    );
  }

  // REMOVE SELECTED CLOUDINARY IMAGE
  removeCloudImage(publicId: string): void {
    this.selectedCloudImages = this.selectedCloudImages.filter(
      (image) => image.public_id !== publicId
    );
  }

  // SUBMIT FORM
  async onSubmit(): Promise<void> {
    this.successMessage = '';
    this.errorMessage = '';

    if (this.isSubmitting) {
      return;
    }

    if (this.tourForm.invalid) {
      this.tourForm.markAllAsTouched();
      this.cdr.detectChanges();
      return;
    }

    this.isSubmitting = true;
    this.cdr.detectChanges();

    try {
      this.renumberDays();

      const formData = new FormData();

      // TOUR INFORMATION
      formData.append(
        'tour_name',
        this.tourForm.get('tour_name')?.value || ''
      );

      formData.append(
        'tour_code',
        String(this.tourForm.get('tour_code')?.value ?? '').trim()
      );

      formData.append(
        'country_id',
        String(this.tourForm.get('country_id')?.value)
      );

      formData.append(
        'type',
        this.tourForm.get('type')?.value || 'ในประเทศ'
      );

      formData.append(
        'duration_day',
        String(this.tourForm.get('duration_day')?.value)
      );

      formData.append(
        'price',
        String(this.tourForm.get('price')?.value)
      );

      formData.append(
        'promotion',
        this.tourForm.get('promotion')?.value || ''
      );

      // CONDITIONS
      const conditionMode =
        this.tourForm.get('condition_mode')?.value ?? 'default';

      const customCondition = String(
        this.tourForm.get('condition_detail')?.value ?? ''
      ).trim();

      formData.append('condition_mode', conditionMode);
      formData.append(
        'condition_detail',
        conditionMode === 'custom' ? customCondition : ''
      );

      formData.append(
        'include_flight',
        this.tourForm.get('include_flight')?.value || 'ไม่รวม'
      );

      formData.append(
        'status',
        this.tourForm.get('status')?.value || 'open'
      );

      // DAILY DETAILS
      formData.append(
        'tour_details',
        JSON.stringify(this.tourDetails.value)
      );

      // EXISTING IMAGES TO KEEP
      formData.append(
        'keep_image_ids',
        JSON.stringify(
          this.existingImages
            .map((image) => Number(image.img_id))
            .filter((id) => Number.isInteger(id) && id > 0)
        )
      );

      // CLOUDINARY IMAGES
      formData.append(
        'cloud_image_ids',
        JSON.stringify(
          this.selectedCloudImages.map((image) => image.public_id)
        )
      );

      // NEW LOCAL IMAGES
      for (const file of this.selectedImages) {
        formData.append('tour_images', file);
      }

      // VIDEO: แนบไฟล์ครั้งเดียว
      if (this.selectedVideo) {
        formData.append('video', this.selectedVideo);
      }

      formData.append(
        'remove_existing_video',
        String(this.removeExistingVideo)
      );

      // PDF: แนบไฟล์ครั้งเดียว
      if (this.selectedPdf) {
        formData.append('pdf_file', this.selectedPdf);
      }

      formData.append(
        'remove_existing_pdf',
        String(this.removeExistingPdf)
      );

      // SEND PUT REQUEST
      const result = await this.api.putData(
        `manage-tour/${this.tourId}`,
        formData
      );

      console.log('EDIT TOUR RESPONSE =', result);

      if (
  result?.statusCode === 200 &&
  result?.body?.success === true
) {
  const message =
    result.body.message || 'แก้ไขข้อมูลทัวร์สำเร็จ';

  // ล้าง Preview URL
  for (const preview of this.selectedImagePreviews) {
    URL.revokeObjectURL(preview);
  }

  // เคลียร์ไฟล์ที่เลือกใหม่
  this.selectedImages = [];
  this.selectedImagePreviews = [];
  this.selectedCloudImages = [];
  this.selectedVideo = null;
  this.selectedPdf = null;

  // รีเซ็ตสถานะการลบไฟล์เดิม
  this.removeExistingVideo = false;
  this.removeExistingPdf = false;

  // โหลดข้อมูลล่าสุดจาก Backend
  await this.loadData();

  // แจ้งเตือนหลังบันทึกสำเร็จ
  alert(message);

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
      console.error('Submit Edit Tour Error:', error);
      this.errorMessage = 'เกิดข้อผิดพลาดในการบันทึกข้อมูล';
    } finally {
      this.isSubmitting = false;
      this.cdr.detectChanges();
    }
  }

  // BACK TO MANAGE TOUR
  back(): void {
    this.router.navigate(['/manage-tour']);
  }

  // DESTROY
  ngOnDestroy(): void {
    for (const preview of this.selectedImagePreviews) {
      URL.revokeObjectURL(preview);
    }
  }
}