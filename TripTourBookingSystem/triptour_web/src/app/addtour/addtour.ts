import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, FormGroup, FormArray, Validators } from '@angular/forms';
import { ServerApi } from '../server/server'; 

@Component({
  selector: 'app-addtour',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule], 
  templateUrl: './addtour.html',
  styleUrl: './addtour.css'
})
export class Addtour implements OnInit {
  tourForm!: FormGroup;

  constructor(private fb: FormBuilder, private api: ServerApi) {}

  ngOnInit() {
    this.tourForm = this.fb.group({
      tour_name: ['', Validators.required],
      country_id: [null, Validators.required],
      type: [''],
      duration_day: [1, Validators.required],
      price: [0, Validators.required],
      video: [''],
      promotion: [''],
      condition_detail: [''],
      include_flight: [''],
      pdf_file: [''],
      status: ['Active'],
      
      tour_details: this.fb.array([]) 
    });

    this.addDay(); 
  }

  get tourDetails() {
    return this.tourForm.get('tour_details') as FormArray;
  }

  addDay() {
    const dayForm = this.fb.group({
      day_number: [this.tourDetails.length + 1],
      day_detail: [''],
      location: [''],
      travel: [''],
      hotel: [''],
      meal_detail: [''],
      restaurant_detail: ['']
    });
    this.tourDetails.push(dayForm);
  }

  removeDay(index: number) {
    this.tourDetails.removeAt(index);
  }

  async onSubmit() {
    if (this.tourForm.invalid) {
      alert('กรุณากรอกข้อมูลที่จำเป็นให้ครบถ้วน');
      return;
    }

    const formData = this.tourForm.value;
    console.log('ข้อมูลที่จะส่งไป Backend:', formData);

    const result = await this.api.postData('add-tour', formData);

    if (result.statusCode === 201) {
      alert('เพิ่มข้อมูลทัวร์สำเร็จ!');
      this.tourForm.reset(); 
      this.tourDetails.clear();
      this.addDay(); 
    } else {
      alert('เกิดข้อผิดพลาด: ' + (result.body.message || result.body.error));
    }
  }
}