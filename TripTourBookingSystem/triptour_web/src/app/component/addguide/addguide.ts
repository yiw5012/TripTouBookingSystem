import { ChangeDetectorRef, Component, inject, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { ServerApi } from '../../server/server'; // 👈 นำเข้า Service API

@Component({
  selector: 'app-add-guide',
  standalone: true,
  imports: [
    ReactiveFormsModule,
    CommonModule
  ],
  templateUrl: './addguide.html',
  styleUrls: ['./addguide.css']
})
export class AddGuide implements OnInit {
  guideForm!: FormGroup;
  isSubmitting = false;
  private cdr = inject(ChangeDetectorRef);
  previewUrl: string | null = null;
selectedImage: File | null = null; // ตัวแปรเก็บรูปโปรไa]N

  constructor(
    private fb: FormBuilder,
    private serverApi: ServerApi
  ) { }

  ngOnInit(): void {
    this.guideForm = this.fb.group({
      email: ['', [Validators.required, Validators.email]],
      password: ['', [Validators.required, Validators.minLength(6)]],
      guide_code: ['', Validators.required],
      first_name: ['', Validators.required],
      last_name: ['', Validators.required],
      phone: ['', [Validators.required, Validators.pattern('^[0-9]{10}$')]],
      age: ['', [Validators.required, Validators.min(18)]],
      birthday: ['', Validators.required],
      address: ['', Validators.required]
    });
  }

  async onSubmit(): Promise<void> {
    if (this.guideForm.invalid) {
      alert('กรุณากรอกข้อมูลให้ครบถ้วนและถูกต้องก่อนบันทึก');
      this.guideForm.markAllAsTouched(); // แสดงผลสีแดงตรงจุดที่ยังกรอกไม่ครบ
      this.cdr.detectChanges();
      return;
    }

    this.isSubmitting = true;
    this.cdr.detectChanges();
    const formData = new FormData();

    // เพิ่มค่าจาก Form Control ลงใน FormData
    Object.keys(this.guideForm.value).forEach(key => {
      const value = this.guideForm.value[key];
      if (value !== null && value !== undefined) {
        if (key === 'age') {
          formData.append(key, String(Number(value)));
        } else {
          formData.append(key, value);
        }
      }
    });

    if (this.selectedImage) {
      formData.append('guideimage_profile', this.selectedImage);
    }

    try {
      const res = await this.serverApi.postData('add-guide', formData);

      this.isSubmitting = false;

      // ✅ เช็กทั้ง statusCode และ status === 'success' ตามที่ Express ส่งมา
      if (
        res.statusCode === 200 ||
        res.statusCode === 201 ||
        res.body?.status === 'success' ||
        res.body?.success
      ) {
        alert('✅ เพิ่มข้อมูลไกด์และอัปโหลดรูปภาพสำเร็จ!');
        this.resetGuideForm();
      } else {
        alert('❌ เกิดข้อผิดพลาด: ' + (res.body?.message || res.message || 'ไม่สามารถสร้างบัญชีไกด์ได้'));
      }

    } catch (err: any) {
      this.isSubmitting = false;
      console.error('Error submitting form:', err);
      alert('❌ เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์');
    } finally {
      this.cdr.detectChanges();
    }
  }

  onImageSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files.length > 0) {
      this.selectedImage = input.files[0];
      // แสดงตัวอย่างรูปภาพ
      const reader = new FileReader();
      reader.onload = (e: any) => {
        this.previewUrl = e.target.result;
      };
      reader.readAsDataURL(this.selectedImage);
    }
  }

  // ฟังก์ชันลบรูปโปรไฟล์
  removeSelectedImage(): void {
    this.guideForm.reset();
    this.selectedImage = null;
    this.previewUrl = null;
  }

  // ฟังก์ชันล้างฟอร์มและรีเซ็ต Validation State ทั้งหมด
  resetGuideForm(): void {
    this.guideForm.reset();
    this.selectedImage = null;
    this.previewUrl = null; 
    Object.keys(this.guideForm.controls).forEach(key => {
      const control = this.guideForm.get(key);
      control?.setErrors(null);
      control?.markAsPristine();
      control?.markAsUntouched();
    });

    this.cdr.detectChanges();
  }
}