import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, FormGroup, FormArray, Validators } from '@angular/forms';
import { ServerApi } from '../server/server'; 

@Component({
  selector: 'app-addtour',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule
  ],
  templateUrl: './addtour.html',
  styleUrl: './addtour.css'
})
export class Addtour implements OnInit {

  // ==========================================================
  // FORM
  // ==========================================================

  tourForm!: FormGroup;


  // ==========================================================
  // FILES
  // ==========================================================

  // รูปภาพหลายรูป
  selectedImages: File[] = [];

  // วิดีโอ 1 ไฟล์
  selectedVideo: File | null = null;

  // PDF 1 ไฟล์
  selectedPdf: File | null = null;


  // ==========================================================
  // STATE
  // ==========================================================

  isSubmitting = false;


  constructor(
    private fb: FormBuilder,
    private api: ServerApi
  ) {}


  // ==========================================================
  // INIT
  // ==========================================================

  ngOnInit(): void {

    this.tourForm = this.fb.group({

      // --------------------------------------------------------
      // ข้อมูลทั่วไป
      // --------------------------------------------------------

      tour_name: [
        '',
        Validators.required
      ],

      country_id: [
        null,
        Validators.required
      ],

      type: [
        'ในประเทศ',
        Validators.required
      ],

      duration_day: [
        1,
        [
          Validators.required,
          Validators.min(1)
        ]
      ],

      price: [
        0,
        [
          Validators.required,
          Validators.min(0)
        ]
      ],

      video: [
        ''
      ],

      promotion: [
        ''
      ],

      condition_detail: [
        ''
      ],

      include_flight: [
        'ไม่รวม',
        Validators.required
      ],

      pdf_file: [
        '',
        Validators.required
      ],

      status: [
        'open',
        Validators.required
      ],


      // --------------------------------------------------------
      // รายละเอียดรายวัน
      // --------------------------------------------------------

      tour_details: this.fb.array([])

    });


    // เพิ่มวันที่ 1
    this.addDay();
  }


  // ==========================================================
  // TOUR DETAILS FORM ARRAY
  // ==========================================================

  get tourDetails(): FormArray {

    return this.tourForm.get(
      'tour_details'
    ) as FormArray;
  }


  // ==========================================================
  // ADD DAY
  // ==========================================================

  addDay(): void {

    const dayNumber =
      this.tourDetails.length + 1;


    const dayForm =
      this.fb.group({

        day_number: [
          dayNumber
        ],

        day_detail: [
          ''
        ],

        location: [
          ''
        ],

        travel: [
          ''
        ],

        hotel: [
          ''
        ],

        meal_detail: [
          ''
        ],

        restaurant_detail: [
          ''
        ]

      });


    this.tourDetails.push(
      dayForm
    );
  }


  // ==========================================================
  // REMOVE DAY
  // ==========================================================

  removeDay(index: number): void {

    this.tourDetails.removeAt(
      index
    );


    // --------------------------------------------------------
    // เรียงเลขวันที่ใหม่
    // --------------------------------------------------------

    this.tourDetails.controls
      .forEach((control, i) => {

        control.get('day_number')
          ?.setValue(i + 1);

      });
  }


  // ==========================================================
  // SELECT IMAGES
  // ==========================================================

  onImagesSelected(
    event: Event
  ): void {

    const input =
      event.target as HTMLInputElement;


    if (!input.files) {
      return;
    }


    const files =
      Array.from(input.files);


    // --------------------------------------------------------
    // ตรวจเฉพาะรูปภาพ
    // --------------------------------------------------------

    const imageFiles =
      files.filter(file =>
        file.type.startsWith('image/')
      );


    if (imageFiles.length !== files.length) {

      alert(
        'สามารถเลือกได้เฉพาะไฟล์รูปภาพเท่านั้น'
      );

    }


    // --------------------------------------------------------
    // จำกัดไม่เกิน 20 รูป
    // ตาม Backend
    // --------------------------------------------------------

    const totalFiles =
      this.selectedImages.length +
      imageFiles.length;


    if (totalFiles > 20) {

      alert(
        'สามารถเพิ่มรูปภาพได้สูงสุด 20 รูป'
      );

      const remaining =
        20 -
        this.selectedImages.length;

      this.selectedImages =
        [
          ...this.selectedImages,
          ...imageFiles.slice(
            0,
            Math.max(0, remaining)
          )
        ];

    } else {

      this.selectedImages =
        [
          ...this.selectedImages,
          ...imageFiles
        ];
    }


    console.log(
      'Selected images =',
      this.selectedImages
    );


    // --------------------------------------------------------
    // เพื่อให้เลือกไฟล์เดิมซ้ำได้ในครั้งต่อไป
    // --------------------------------------------------------

    input.value = '';
  }


  // ==========================================================
  // REMOVE IMAGE
  // ==========================================================

  removeSelectedImage(
    index: number
  ): void {

    this.selectedImages.splice(
      index,
      1
    );

    this.selectedImages =
      [...this.selectedImages];
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
      input.files?.[0] ?? null;


    if (!file) {
      return;
    }


    // --------------------------------------------------------
    // ตรวจชนิดไฟล์
    // --------------------------------------------------------

    if (!file.type.startsWith('video/')) {

      alert(
        'กรุณาเลือกไฟล์วิดีโอเท่านั้น'
      );

      input.value = '';

      return;
    }


    this.selectedVideo =
      file;


    console.log(
      'Selected video =',
      this.selectedVideo
    );


    input.value = '';
  }


  // ==========================================================
  // REMOVE VIDEO
  // ==========================================================

  removeSelectedVideo(): void {

    this.selectedVideo =
      null;
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
      input.files?.[0] ?? null;


    if (!file) {
      return;
    }


    // --------------------------------------------------------
    // ตรวจ PDF
    // --------------------------------------------------------

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


    this.selectedPdf =
      file;

    this.tourForm
  .get('pdf_file')
  ?.setValue(file.name);

this.tourForm
  .get('pdf_file')
  ?.updateValueAndValidity();


    console.log(
      'Selected PDF =',
      this.selectedPdf
    );


    input.value = '';
  }


  // ==========================================================
  // REMOVE PDF
  // ==========================================================

 removeSelectedPdf(): void {

  this.selectedPdf = null;

  this.tourForm
    .get('pdf_file')
    ?.setValue('');

  this.tourForm
    .get('pdf_file')
    ?.updateValueAndValidity();
}


  // ==========================================================
  // SUBMIT
  // ==========================================================

  async onSubmit(): Promise<void> {

    // --------------------------------------------------------
    // ป้องกันกดซ้ำ
    // --------------------------------------------------------

    if (this.isSubmitting) {
      return;
    }


    // --------------------------------------------------------
    // ตรวจ Form
    // --------------------------------------------------------

    if (this.tourForm.invalid) {

      this.tourForm.markAllAsTouched();

      alert(
        'กรุณากรอกข้อมูลที่จำเป็นให้ครบถ้วน'
      );

      return;
    }


    // --------------------------------------------------------
    // PDF จำเป็น
    // --------------------------------------------------------

    if (!this.selectedPdf) {

      alert(
        'กรุณาเลือกไฟล์ PDF ของโปรแกรมทัวร์'
      );

      return;
    }


    this.isSubmitting =
      true;


    try {

      // ======================================================
      // สร้าง FormData
      // ======================================================

      const formData =
        new FormData();


      // ======================================================
      // ข้อมูลหลัก
      // ======================================================

      formData.append(
        'tour_name',
        this.tourForm
          .get('tour_name')
          ?.value ?? ''
      );


      formData.append(
        'country_id',
        String(
          this.tourForm
            .get('country_id')
            ?.value ?? ''
        )
      );


      formData.append(
        'type',
        this.tourForm
          .get('type')
          ?.value ?? ''
      );


      formData.append(
        'duration_day',
        String(
          this.tourForm
            .get('duration_day')
            ?.value ?? ''
        )
      );


      formData.append(
        'price',
        String(
          this.tourForm
            .get('price')
            ?.value ?? ''
        )
      );


      formData.append(
        'promotion',
        this.tourForm
          .get('promotion')
          ?.value ?? ''
      );


      formData.append(
        'condition_detail',
        this.tourForm
          .get('condition_detail')
          ?.value ?? ''
      );


      formData.append(
        'include_flight',
        this.tourForm
          .get('include_flight')
          ?.value ?? ''
      );


      formData.append(
        'status',
        this.tourForm
          .get('status')
          ?.value ?? 'open'
      );


      // ======================================================
      // TOUR DETAILS
      // ======================================================

      const tourDetails =
        this.tourDetails.value;


      formData.append(
        'tour_details',
        JSON.stringify(
          tourDetails
        )
      );


      // ======================================================
      // รูปภาพหลายรูป
      // ======================================================

      for (
        const image of this.selectedImages
      ) {

        formData.append(
          'tour_images',
          image
        );

      }


      // ======================================================
      // วิดีโอ
      // ======================================================

      if (this.selectedVideo) {

        formData.append(
          'video',
          this.selectedVideo
        );

      }


      // ======================================================
      // PDF
      // ======================================================

      formData.append(
        'pdf_file',
        this.selectedPdf
      );


      // ======================================================
      // DEBUG
      // ======================================================

      console.log(
        '===================================='
      );

      console.log(
        'ADD TOUR FORM DATA'
      );

      console.log(
        'tour_name =',
        this.tourForm
          .get('tour_name')
          ?.value
      );

      console.log(
        'country_id =',
        this.tourForm
          .get('country_id')
          ?.value
      );

      console.log(
        'type =',
        this.tourForm
          .get('type')
          ?.value
      );

      console.log(
        'duration_day =',
        this.tourForm
          .get('duration_day')
          ?.value
      );

      console.log(
        'price =',
        this.tourForm
          .get('price')
          ?.value
      );

      console.log(
        'images =',
        this.selectedImages.length
      );

      console.log(
        'video =',
        this.selectedVideo
      );

      console.log(
        'pdf =',
        this.selectedPdf
      );

      console.log(
        'tour_details =',
        tourDetails
      );

      console.log(
        '===================================='
      );


      // ======================================================
      // SEND BACKEND
      // ======================================================

      const result =
        await this.api.postData(
          'add-tour',
          formData
        );


      console.log(
        'ADD TOUR RESULT =',
        result
      );


      // ======================================================
      // SUCCESS
      // ======================================================

      if (
        result?.statusCode === 201 &&
        result?.body?.success === true
      ) {

        const newTourId =
          result.body.data?.tour_id ??
          result.body.tour_id;


        alert(
          `เพิ่มข้อมูลทัวร์สำเร็จ${
            newTourId
              ? `\nรหัสทัวร์: ${newTourId}`
              : ''
          }`
        );


        // ----------------------------------------------------
        // Reset Form
        // ----------------------------------------------------

        this.tourForm.reset({

          tour_name: '',

          country_id: null,

          type: 'ในประเทศ',

          duration_day: 1,

          price: 0,

          video: '',

          promotion: '',

          condition_detail: '',

          include_flight: 'ไม่รวม',

          pdf_file: '',

          status: 'open'

        });


        // ----------------------------------------------------
        // ล้างรายละเอียดเดิม
        // ----------------------------------------------------

        this.tourDetails.clear();


        // ----------------------------------------------------
        // เพิ่มวันที่ 1 กลับมา
        // ----------------------------------------------------

        this.addDay();


        // ----------------------------------------------------
        // ล้างไฟล์
        // ----------------------------------------------------

        this.selectedImages = [];

        this.selectedVideo = null;

        this.selectedPdf = null;


      } else {

        alert(
          result?.body?.message ??
          result?.body?.error ??
          'เกิดข้อผิดพลาดในการบันทึกข้อมูลทัวร์'
        );

      }

    } catch (error) {

      console.error(
        'ADD TOUR ERROR =',
        error
      );


      alert(
        'เกิดข้อผิดพลาดในการเชื่อมต่อกับเซิร์ฟเวอร์'
      );

    } finally {

      this.isSubmitting =
        false;
    }
  }
}