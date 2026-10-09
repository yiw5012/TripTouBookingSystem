import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class ServerApi {
  private readonly baseUrl = 'http://localhost:4000';

  constructor(private http: HttpClient) {}

  async postData(endpoint: string, bodyData: any): Promise<any> {
    const cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    const url = `${this.baseUrl}/${cleanEndpoint}`;
    
    try {
      const response = await firstValueFrom(
        this.http.post<any>(url, bodyData, { observe: 'response' })
      );

      return { 
        statusCode: response.status, 
        body: response.body 
      };
    } catch (error: any) {
      console.error('API Error:', error);
      return {
        statusCode: error.status || 500,
        body: error.error || { message: 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้' }
      };
    }
  }

  async patchData(endpoint: string, bodyData: any): Promise<any> {
    const cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    const url = `${this.baseUrl}/${cleanEndpoint}`;

    try {
      const response = await firstValueFrom(
        this.http.patch<any>(url, bodyData, { observe: 'response' })
      );

      return {
        statusCode: response.status,
        body: response.body
      };
    } catch (error: any) {
      console.error('API Error:', error);
      return {
        statusCode: error.status || 500,
        body: error.error || { message: 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้' }
      };
    }
  }
  async putData(endpoint: string, bodyData: any): Promise<any> {
    const cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    const url = `${this.baseUrl}/${cleanEndpoint}`;

    try {
      const response = await firstValueFrom(
        this.http.put<any>(url, bodyData, { observe: 'response' })
      );

      return {
        statusCode: response.status,
        body: response.body
      };
    } catch (error: any) {
      console.error('API Error:', error);
      return {
        statusCode: error.status || 500,
        body: error.error || { message: 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้' }
      };
    }
  }

async getDashboardData(endpoint: string, params?: Record<string, string>, bodyData?: any): Promise<any> {
  
    const cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    const url = `${this.baseUrl}/${cleanEndpoint}`;
    
    let httpParams = new HttpParams();
    if (params) {
      Object.keys(params).forEach(key => {
        const val = params[key];
        if (val !== null && val !== undefined && val !== '') {
          httpParams = httpParams.set(key, String(val));
        }
      });
    }

    try {
      const response = await firstValueFrom(
        this.http.get(url, { params: httpParams, observe: 'response' })
      );

      return {
        statusCode: response.status,
        body: response.body
      };
    } catch (error: any) {
      console.error('API Error:', error);
      return {
        statusCode: error.status || 500,
        body: error.error || { message: 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้' }
      };
    }
  }
}