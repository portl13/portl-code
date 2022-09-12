/*tslint:disable:curly*/
import { Injectable } from '@angular/core';
import { LocalStorageAPIService } from './shared/local-storage-api.service';

// mocked data
import { dataCounts, artists, events, venues } from './mocked-data';
import { Subject } from 'rxjs/Subject';

@Injectable()
export class AppService {

  constructor(private localStorageAPIService: LocalStorageAPIService) {}

  private alertsSubject = new Subject<Alert>();
  alerts$ = this.alertsSubject.asObservable();

  postAlert(alert: Alert) {
    this.alertsSubject.next(alert);
  }

  setInitialData() {
    // const data: any = this.localStorageAPIService.getAllData();
    // if (data && data.dataCounts && data.artists && data.events && data.venues) return;

    const appData = {
      dataCounts,
      artists,
      events,
      venues
    };

    this.localStorageAPIService.setData('appData', appData);
  }
}

export interface Alert {
  type: 'success' | 'info' | 'warning' | 'danger';
  msg: string;
  timeout?: number;
}
