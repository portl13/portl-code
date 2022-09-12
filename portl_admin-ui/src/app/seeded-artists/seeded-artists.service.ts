/*tslint:disable:curly*/
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';

import { Subject } from 'rxjs/Subject';

import { SeededArtist, SeededArtistParams, SEEDED_ARTIST } from './seeded-artist.type';

import { RemoteApiService } from '../shared/remote-api.service';
import { ConfigService } from '../shared/config.service';
import { Observable } from 'rxjs/Observable';
import { ImportResults } from './seeded-artists-csv-upload/import-results.type';

@Injectable()
export class SeededArtistsService {
  updateSeededArtistsSubscription: Subject<any> = new Subject();

  constructor(private httpClient: HttpClient,
              private configService: ConfigService,
              private remoteApiService: RemoteApiService) {}

  // CRUD
  getSeededArtists(filters: SeededArtistParams = {}) {
    return this.remoteApiService.getList(SEEDED_ARTIST, filters);
  }

  updateSeededArtistsList() {
    this.updateSeededArtistsSubscription.next();
  }

  updateSeededArtist(id: String, artist: SeededArtist) {
    return this.remoteApiService.update<SeededArtist>(SEEDED_ARTIST, id, artist);
  }

  deleteSeededArtist(id: String) {
    return this.remoteApiService.delete<SeededArtist>(SEEDED_ARTIST, id);
  }

  createSeededArtist(artist: SeededArtist) {
    return this.remoteApiService.create<SeededArtist>(SEEDED_ARTIST, artist);
  }

  // BULK
  bulkCreateCSV(csvFile: File): Observable<ImportResults> {
    const url = `${this.configService.getConfig('apiUrl')}/${SEEDED_ARTIST}/bulkCreate`;
    const fileKey = 'artistNames';
    const form = new FormData();
    form.append(fileKey, csvFile);

    return this.httpClient.post<ImportResults>(url, form);
  }
}
