/*tslint:disable:curly*/
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs/Observable';
import { catchError } from 'rxjs/operators';

import { LocalStorageAPIService } from '../shared/local-storage-api.service';

import { Subject } from 'rxjs/Subject';
import { Event, EventsParams, EVENT } from './event.type';
import { Artist, ArtistParams, ARTIST } from '../artists/artist.type';
import { Venue, VenueParams, VENUE } from '../venues/venue.type';
import { RemoteApiService } from '../shared/remote-api.service';

import { ConfigService } from '../shared/config.service';
import { ImportResults } from './events-csv-upload/import-results.type';


const categories = [ 'Music', 'Family', 'Sports', 'Business', 'Theatre', 'Food', 'Film',
                   'Yoga', 'Fashion', 'Community', 'Science', 'Travel', 'Museum' ];

@Injectable()
export class EventsService {
  updateEventsSubscription: Subject<any> = new Subject();

  constructor(private httpClient: HttpClient,
              private configService: ConfigService,
              private localStorageAPIService: LocalStorageAPIService,
              private remoteApiService: RemoteApiService) {}


  getEvents(filters: EventsParams = {}) {
    return this.remoteApiService.getList(EVENT, filters);
  }

  getEventDetail(id: String) {
    return this.remoteApiService.getDetail(EVENT, id);
  }

  getArtists() {
    return this.remoteApiService.getList(ARTIST, {});
  }

  getVenues() {
    return this.remoteApiService.getList(VENUE, {});
  }

  getCategories() {
    return categories;
  }

  updateEventsList() {
    this.updateEventsSubscription.next();
  }

  updateEvent(id: String, event: Event) {
    return this.remoteApiService.update<Event>(EVENT, id, event);
  }

  deleteEvent(id: String) {
    return this.remoteApiService.delete<Event>(EVENT, id);
  }

  createEvent(event: Event) {
    return this.remoteApiService.create<Event>(EVENT, event);
  }

  // BULK
  bulkCreateCSV(csvFile: File): Observable<ImportResults> {
    const url = `${this.configService.getConfig('apiUrl')}/${EVENT}/bulkCreate`;
    const fileKey = 'eventTitles';
    const form = new FormData();
    form.append(fileKey, csvFile);

    return this.httpClient.post<ImportResults>(url, form);
  }
}
