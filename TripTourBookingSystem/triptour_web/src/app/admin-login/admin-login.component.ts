import { Component, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { NgIf } from '@angular/common';
import { AdminAuthService } from '../admin-auth.service';

@Component({
  selector: 'app-admin-login',
  standalone: true,
  imports: [ReactiveFormsModule, NgIf],
  template: `
    <div class="admin-login-shell">
      <div class="login-card">
        <div class="brand-block">
          <div class="brand-badge">T</div>
          <div>
            <p class="eyebrow">Admin access</p>
            <h1>TripTour Booking</h1>
          </div>
        </div>

        <h2>เข้าสู่ระบบผู้ดูแล</h2>

        <form [formGroup]="loginForm" (ngSubmit)="submit()">
          <label for="email">อีเมล</label>
          <input
            id="email"
            type="email"
            formControlName="email"
            placeholder="admin@triptour.com"
          />

          <label for="password">รหัสผ่าน</label>
          <input
            id="password"
            type="password"
            formControlName="password"
            placeholder="••••••••"
          />

          <div class="error-message" *ngIf="errorMessage">
            {{ errorMessage }}
          </div>

          <button type="submit" [disabled]="loginForm.invalid || isSubmitting">
            {{ isSubmitting ? 'กำลังเข้าสู่ระบบ...' : 'เข้าสู่ระบบ' }}
          </button>
        </form>

        <div class="hint-box">
          <strong>หมายเหตุ:</strong>
          <div>ใช้บัญชีแอดมินที่มีสิทธิ์ใน Firebase Authentication</div>
        </div>
      </div>
    </div>
  `,
  styles: [
    `
      :host {
        display: block;
        width: 100%;
        height: 100vh;
        background: linear-gradient(135deg, #eafaf1 0%, #f3f8ff 100%);
      }

      .admin-login-shell {
        height: 100%;
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 24px;
      }

      .login-card {
        width: min(100%, 440px);
        background: #ffffff;
        border-radius: 22px;
        padding: 32px 28px;
        box-shadow: 0 15px 45px rgba(17, 74, 47, 0.12);
        border: 1px solid rgba(31, 174, 91, 0.08);
      }

      .brand-block {
        display: flex;
        align-items: center;
        gap: 14px;
        margin-bottom: 24px;
      }

      .brand-badge {
        width: 52px;
        height: 52px;
        border-radius: 16px;
        display: flex;
        align-items: center;
        justify-content: center;
        background: linear-gradient(135deg, #1fae5b, #16a34a);
        color: #fff;
        font-size: 28px;
        font-weight: 700;
      }

      .eyebrow {
        margin: 0;
        font-size: 12px;
        letter-spacing: 0.08em;
        text-transform: uppercase;
        color: #2a996d;
      }

      h1 {
        margin: 4px 0 0;
        font-size: 26px;
      }

      h2 {
        margin: 0 0 20px;
        font-size: 24px;
        color: #202935;
      }

      form {
        display: flex;
        flex-direction: column;
        gap: 12px;
      }

      label {
        font-size: 14px;
        font-weight: 600;
        color: #2d3748;
      }

      input {
        width: 100%;
        border: 1px solid #dfe6e8;
        border-radius: 12px;
        padding: 12px 14px;
        font-size: 15px;
        box-sizing: border-box;
        transition: border-color 0.2s ease;
      }

      input:focus {
        outline: none;
        border-color: #1fae5b;
        box-shadow: 0 0 0 3px rgba(31, 174, 91, 0.12);
      }

      button {
        margin-top: 8px;
        border: none;
        border-radius: 12px;
        padding: 14px 18px;
        background: linear-gradient(135deg, #1fae5b, #16a34a);
        color: #fff;
        font-size: 16px;
        font-weight: 700;
        cursor: pointer;
      }

      button:disabled {
        opacity: 0.7;
        cursor: not-allowed;
      }

      .error-message {
        background: #fff1f2;
        color: #b42318;
        border: 1px solid #fecdd3;
        border-radius: 10px;
        padding: 10px 12px;
        font-size: 14px;
      }

      .hint-box {
        margin-top: 20px;
        padding: 12px 14px;
        border-radius: 12px;
        background: #f3faf6;
        color: #1f3b2b;
        font-size: 13px;
        line-height: 1.7;
      }
    `,
  ],
})
export class AdminLoginComponent {
  private readonly auth = inject(AdminAuthService);
  private readonly router = inject(Router);
  private readonly fb = inject(FormBuilder);

  isSubmitting = false;
  errorMessage = '';

  loginForm = this.fb.nonNullable.group({
    email: ['', [Validators.required, Validators.email]],
    password: ['', [Validators.required]],
  });

  async submit(): Promise<void> {
    if (this.loginForm.invalid) {
      this.loginForm.markAllAsTouched();
      this.errorMessage = 'กรุณากรอกข้อมูลให้ครบถ้วน';
      return;
    }

    this.isSubmitting = true;
    this.errorMessage = '';

    const { email, password } = this.loginForm.getRawValue();
    const success = await this.auth.login(email, password);

    if (!success) {
      this.isSubmitting = false;
      this.errorMessage = 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
      window.alert('เข้าสู่ระบบไม่สำเร็จ: อีเมลหรือรหัสผ่านไม่ถูกต้อง');
      return;
    }

    this.isSubmitting = false;
    this.router.navigate(['/dashboard']);
  }
}
