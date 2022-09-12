/*tslint:disable:curly*/
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { catchError } from 'rxjs/operators';

import { Subject } from 'rxjs/Subject';

import { Artist, ArtistParams, ARTIST } from './artist.type';

import { LocalStorageAPIService } from '../shared/local-storage-api.service';
import { RemoteApiService } from '../shared/remote-api.service';
import { Observable } from 'rxjs/Observable';
import { ImportResults } from '../seeded-artists/seeded-artists-csv-upload/import-results.type';
import { SEEDED_ARTIST } from '../seeded-artists/seeded-artist.type';
import { ConfigService } from '../shared/config.service';

@Injectable()
export class ArtistsService {
  updateArtistsSubscription: Subject<any> = new Subject();

  constructor(private httpClient: HttpClient,
              private configService: ConfigService,
              private localStorageAPIService: LocalStorageAPIService,
              private remoteApiService: RemoteApiService) {}

  getArtists(filters: ArtistParams = {}) {
    return this.remoteApiService.getList(ARTIST, filters);
  }

  updateArtistsList() {
    this.updateArtistsSubscription.next();
  }

  updateArtist(id: String, artist: Artist) {
    return this.remoteApiService.update<Artist>(ARTIST, id, artist);
  }

  deleteArtist(id: String) {
    return this.remoteApiService.delete<Artist>(ARTIST, id);
  }

  createArtist(artist: Artist) {
    return this.remoteApiService.create<Artist>(ARTIST, artist);
  }

  // BULK
  bulkCreateCSV(csvFile: File): Observable<ImportResults> {
    const url = `${this.configService.getConfig('apiUrl')}/${ARTIST}/bulkCreate`;
    const fileKey = 'file';
    const form = new FormData();
    form.append(fileKey, csvFile);

    return this.httpClient.post<ImportResults>(url, form);
  }
}
