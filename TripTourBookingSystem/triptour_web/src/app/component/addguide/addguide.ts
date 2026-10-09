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

  constructor(
    private fb: FormBuilder,
    private serverApi: ServerApi 
  ) {}

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

    // เตรียม Payload และแปลงค่าอายุเป็นตัวเลข
    const payload = {
      ...this.guideForm.value,
      age: Number(this.guideForm.value.age)
    };

    try {
      const res = await this.serverApi.postData('add-guide', payload);

      this.isSubmitting = false;

      // ✅ เช็กทั้ง statusCode และ status === 'success' ตามที่ Express ส่งมา
      if (
        res.statusCode === 200 || 
        res.statusCode === 201 || 
        res.body?.status === 'success' ||
        res.body?.success
      ) {
        alert('✅ เพิ่มข้อมูลไกด์สำเร็จ!');
        this.resetGuideForm();
      } else {
        alert('❌ เกิดข้อผิดพลาด: ' + (res.body?.message || res.message || 'ไม่สามารถสร้างบัญชีไกด์ได้'));
      }

    } catch (err: any) {
      this.isSubmitting = false;
      console.error('Error submitting form:', err);
      alert('❌ เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์');
    } finally {
      // ✅ บังคับอัปเดต UI เสมอ ไม่ว่าสำเร็จหรือล้มเหลว
      this.cdr.detectChanges();
    }
  }

  // ฟังก์ชันล้างฟอร์มและรีเซ็ต Validation State ทั้งหมด
  resetGuideForm(): void {
    this.guideForm.reset();
    
    // เคลียร์สถานะ touched และ errors ออก เพื่อไม่ให้ขึ้นกรอบสีแดง
    Object.keys(this.guideForm.controls).forEach(key => {
      const control = this.guideForm.get(key);
      control?.setErrors(null);
      control?.markAsPristine();
      control?.markAsUntouched();
    });

    this.cdr.detectChanges();
  }
}