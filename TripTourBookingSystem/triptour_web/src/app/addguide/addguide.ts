import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { CommonModule } from '@angular/common';

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

  constructor(
    private fb: FormBuilder,
    private http: HttpClient
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

  onSubmit() {
    if (this.guideForm.valid) {
      this.isSubmitting = true;

      this.http.post('http://localhost:4000/add-guide', this.guideForm.value).subscribe({
        next: (res: any) => {
          this.isSubmitting = false;
          alert('✅ เพิ่มข้อมูลไกด์สำเร็จ!'); 
          this.guideForm.reset();
        },
        error: (err) => {
          this.isSubmitting = false;
          console.error(err);
          alert('❌ เกิดข้อผิดพลาด: ' + (err.error.message || 'เซิร์ฟเวอร์ขัดข้อง'));
        }
      });
    } else {
      alert('กรุณากรอกข้อมูลให้ครบถ้วนก่อนบันทึก');
    }
  }
}