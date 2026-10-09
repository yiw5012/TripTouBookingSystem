import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class ServerApi {
  private readonly baseUrl = 'http://localhost:4000';

  constructor(private http: HttpClient) {}

  // async postData(endpoint: string, bodyData: any): Promise<any> {
  //   const cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
  //   const url = `${this.baseUrl}/${cleanEndpoint}`;
    
  //   try {
  //     const response = await firstValueFrom(
  //       this.http.post<any>(url, bodyData, { observe: 'response' })
  //     );

  //     return { 
  //       statusCode: response.status, 
  //       body: response.body 
  //     };
  //   } catch (error: any) {
  //     console.error('API Error:', error);
  //     return {
  //       statusCode: error.status || 500,
  //       body: error.error || { message: 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้' }
  //     };
  //   }
  // } 

  // ==========================================================
  // GET
  // ==========================================================

  async getData(endpoint: string): Promise<any> {

    const url = `${this.baseUrl}/${endpoint}`;

    console.log('====================================');
    console.log('GET REQUEST');
    console.log('URL =', url);
    console.log('====================================');

    try {

      const response = await firstValueFrom(
        this.http.get<any>(url, {
          observe: 'response'
        })
      );

      console.log('GET RESPONSE STATUS =', response.status);
      console.log('GET RESPONSE BODY =', response.body);

      return {
        statusCode: response.status,
        body: response.body
      };

    } catch (error: any) {

      console.error('GET ERROR =', error);

      return {
        statusCode: error?.status ?? 0,
        body: error?.error ?? null,
        error: error
      };
    }
  }

  // ==========================================================
  // POST
  // ==========================================================

  async postData(endpoint: string, data: any): Promise<any> {

    const url = `${this.baseUrl}/${endpoint}`;

    console.log('POST URL =', url);
    console.log('POST DATA =', data);

    try {

      const response = await firstValueFrom(
        this.http.post<any>(url, data, {
          observe: 'response'
        })
      );

      return {
        statusCode: response.status,
        body: response.body
      };

    } catch (error: any) {

      console.error('POST ERROR =', error);

      return {
        statusCode: error?.status ?? 0,
        body: error?.error ?? null,
        error: error
      };
    }
  }

  // ==========================================================
  // PUT
  // ==========================================================

  async putData(endpoint: string, data: any): Promise<any> {

  const url = `${this.baseUrl}/${endpoint}`;

  console.log('====================================');
  console.log('PUT REQUEST');
  console.log('URL =', url);
  console.log('DATA =', data);
  console.log('====================================');

  try {

    const response = await firstValueFrom(
      this.http.put<any>(
        url,
        data,
        {
          observe: 'response',
        }
      )
    );

    console.log('====================================');
    console.log('PUT RESPONSE');
    console.log('STATUS =', response.status);
    console.log('BODY =', response.body);
    console.log('====================================');

    return {
      statusCode: response.status,
      body: response.body,
    };

  } catch (error: any) {

    console.error('====================================');
    console.error('PUT ERROR');
    console.error('STATUS =', error?.status);
    console.error('STATUS TEXT =', error?.statusText);
    console.error('ERROR BODY =', error?.error);
    console.error('MESSAGE =', error?.message);
    console.error('FULL ERROR =', error);
    console.error('====================================');

    return {
      statusCode: error?.status ?? 0,
      body: error?.error ?? null,
      error,
    };
  }
}

  // ==========================================================
  // DELETE
  // ==========================================================

  async deleteData(endpoint: string): Promise<any> {

    const url = `${this.baseUrl}/${endpoint}`;

    console.log('DELETE URL =', url);

    try {

      const response = await firstValueFrom(
        this.http.delete<any>(url, {
          observe: 'response'
        })
      );

      return {
        statusCode: response.status,
        body: response.body
      };

    } catch (error: any) {

      console.error('DELETE ERROR =', error);

      return {
        statusCode: error?.status ?? 0,
        body: error?.error ?? null,
        error: error
      };
    }
  }
}