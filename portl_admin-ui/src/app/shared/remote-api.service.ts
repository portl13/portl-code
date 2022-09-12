import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs/Observable';
import { ConfigService } from './config.service';


type EntityName = 'artist' | 'event' | 'venue' | 'seededArtist';

@Injectable()
export class RemoteApiService {

  constructor(
    private configService: ConfigService,
    private http: HttpClient
  ) {
  }

  getList<EntityType, ParamType>(dataName: EntityName, params: ParamType): Observable<EntityType> {
    let url = `${this.configService.getConfig('apiUrl')}/${dataName}`;
    if (params) {
      const paramsString = Object.keys(params).map(key =>
        encodeURIComponent(key) + '=' + encodeURIComponent(params[key])
      ).join('&');
      url += `?${paramsString}`;
    }
    return this.http.get<EntityType>(url);
  }

  getDetail<EntityType, ParamType>(dataName: EntityName, id: String): Observable<EntityType> {
    return this.http.get<EntityType>(`${this.configService.getConfig('apiUrl')}/${dataName}/${id}`);
  }

  create<EntityType>(dataName: EntityName, data: EntityType): Observable<EntityType> {
    return this.http.post<EntityType>(`${this.configService.getConfig('apiUrl')}/${dataName}`, data);
  }

  update<EntityType>(dataName: EntityName, id: String, data: EntityType): Observable<EntityType> {
    return this.http.put<EntityType>(`${this.configService.getConfig('apiUrl')}/${dataName}/${id}`, data);
  }

  delete<EntityType>(dataName: EntityName, id: String): Observable<EntityType> {
    return this.http.delete<EntityType>(`${this.configService.getConfig('apiUrl')}/${dataName}/${id}`);
  }
}
