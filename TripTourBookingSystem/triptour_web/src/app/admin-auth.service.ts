import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { initializeApp } from 'firebase/app';
import {
  getAuth,
  signInWithEmailAndPassword,
  signOut,
} from 'firebase/auth';
import { firstValueFrom } from 'rxjs';
import { environment } from '../environments/environment.development';

interface AdminLoginResponse {
  success: boolean;
  message?: string;
  token?: string;
  user?: {
    email: string;
    role: string;
  };
}

@Injectable({ providedIn: 'root' })
export class AdminAuthService {
  private readonly storageKey = 'triptour_admin_session';
  private readonly apiBaseUrl = 'http://localhost:4000';
  private readonly http = inject(HttpClient);
  private readonly firebaseApp = initializeApp(environment.firebaseConfig);
  private readonly auth = getAuth(this.firebaseApp);

  async login(email: string, password: string): Promise<boolean> {
    try {
      const userCredential = await signInWithEmailAndPassword(
        this.auth,
        email.trim(),
        password.trim(),
      );

      const idToken = await userCredential.user.getIdToken();

      const response = await firstValueFrom(
        this.http.post<AdminLoginResponse>(`${this.apiBaseUrl}/api/admin/verify-token`, {
          idToken,
        }),
      );

      if (!response.success || !response.token) {
        return false;
      }

      localStorage.setItem(
        this.storageKey,
        JSON.stringify({
          email: response.user?.email ?? userCredential.user.email ?? email.trim().toLowerCase(),
          role: response.user?.role ?? 'admin',
          token: response.token,
          loggedInAt: new Date().toISOString(),
        }),
      );

      return true;
    } catch {
      return false;
    }
  }

  async logout(): Promise<void> {
    try {
      await signOut(this.auth);
    } catch {
      // Ignore sign-out errors and still clear local session.
    }

    localStorage.removeItem(this.storageKey);
  }

  isAuthenticated(): boolean {
    const raw = localStorage.getItem(this.storageKey);
    if (!raw) return false;

    try {
      const data = JSON.parse(raw) as { role?: string; token?: string };
      return Boolean(data.role === 'admin' && data.token);
    } catch {
      return false;
    }
  }

  getSession(): { email: string; role: string; token: string } | null {
    const raw = localStorage.getItem(this.storageKey);
    if (!raw) return null;

    try {
      const data = JSON.parse(raw) as {
        email?: string;
        role?: string;
        token?: string;
      };

      if (!data.email || !data.role || !data.token) return null;
      return {
        email: data.email,
        role: data.role,
        token: data.token,
      };
    } catch {
      return null;
    }
  }
}
