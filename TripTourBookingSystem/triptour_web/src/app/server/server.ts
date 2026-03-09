import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
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
}