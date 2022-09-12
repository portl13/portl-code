import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';

@Injectable()
export class ConfigService {

  private config: Object = null;

  constructor(private http: HttpClient) { }

  configUrl = 'assets/config.json';

  public getConfig(key: any) {
    return this.config[key];
  }

  public load() {
    return new Promise((resolve, reject) => {
      this.http.get<Config>(this.configUrl).subscribe((responseData) => {
        this.config = responseData;
        resolve(true);
      });

    });
  }

}

export interface Config {
  apiUrl: string;
}
