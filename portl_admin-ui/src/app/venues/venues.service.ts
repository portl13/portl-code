/*tslint:disable:curly*/
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { catchError } from 'rxjs/operators';

import { Subject } from 'rxjs/Subject';

import { Venue, VenueParams, VENUE } from './venue.type';

import { LocalStorageAPIService } from '../shared/local-storage-api.service';
import { RemoteApiService } from '../shared/remote-api.service';

@Injectable()
export class VenuesService {
  updateVenuesSubscription: Subject<any> = new Subject();

  constructor(private httpClient: HttpClient,
              private localStorageAPIService: LocalStorageAPIService,
              private remoteApiService: RemoteApiService) {}

  getVenues(filters: any = {}) {
    return this.remoteApiService.getList(VENUE, filters);
  }

  updateVenuesList() {
    this.updateVenuesSubscription.next();
  }

  updateVenue(id: String, venue: Venue) {
    return this.remoteApiService.update<Venue>(VENUE, id, venue);
  }

  deleteVenue(id: String) {
    return this.remoteApiService.delete<Venue>(VENUE, id);
  }

  createVenue(venue: Venue) {
    return this.remoteApiService.create<Venue>(VENUE, venue);
  }
}
