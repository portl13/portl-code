import { Injectable } from '@angular/core';
import { Observable } from 'rxjs/Observable';
import {
  HttpHeaders,
  HttpRequest,
  HttpClient,
  HttpEvent,
  HttpEventType,
} from '@angular/common/http';
import { ConfigService } from './config.service';
import { flatMap, map } from 'rxjs/operators';


export interface UploadStatus {
  state: 'fetching-config' | 'uploading' | 'complete' | 'failed';
  progress: number; // upload progress, between 0 and 1
  publicURL?: string;
  error?: string;
}

interface FileUploadConfig {
  uploadURL: string;
  publicURL: string;
}

interface CreateMediaUploadURLRequest {
  filename: string;
}

@Injectable()
export class FileUploadService {

  constructor(
    private configService: ConfigService,
    private httpClient: HttpClient,
  ) {
  }

  uploadFile(file): Observable<UploadStatus> {
    return this.getS3UploadURL(file.name)
      .pipe(
        // flatMap with Array.of to pass both config and upload events to next stage
        flatMap(config => this.uploadFileS3(config.uploadURL, file), Array.of),
        map(([config, event]: [FileUploadConfig, HttpEvent<any>]) => {
          // HttpSentEvent | HttpHeaderResponse | HttpResponse<T> | HttpProgressEvent | HttpUserEvent<T>
          let status: UploadStatus;
          if (event.type === HttpEventType.UploadProgress) {
            status = {
              state: 'uploading',
              progress: event.total ? event.loaded / event.total : 0
            };
          } else if (event.type === HttpEventType.Response) {
            status = {
              state: 'complete',
              progress: 1,
              publicURL: (config as FileUploadConfig).publicURL
            };
          } else {
            status = {
              state: 'uploading',
              progress: 0
            };
          }
          return status;
        }),
      );
  }

  private getS3UploadURL(filename: string): Observable<FileUploadConfig> {
    const url = `${this.configService.getConfig('apiUrl')}/fileUploadConfig`;
    const body: CreateMediaUploadURLRequest = {filename};
    return this.httpClient.post<FileUploadConfig>(url, body);
  }

  private uploadFileS3(uploadURL, file): Observable<HttpEvent<any>> {
    const headers = new HttpHeaders({
      'Content-Type': file.type
    });
    const req = new HttpRequest('PUT',
      uploadURL,
      file,
      {
        headers: headers,
        reportProgress: true,
      });
    return this.httpClient.request(req);
  }
}
