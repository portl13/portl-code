import { Component, OnInit, OnDestroy } from '@angular/core';

import { Alert, AppService } from './app.service';
import { Subscription } from 'rxjs/Subscription';
import { Router, NavigationEnd } from '@angular/router';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.scss']
})
export class AppComponent implements OnInit, OnDestroy {

  alerts: Alert[] = [];
  private readonly alertsSubscription: Subscription;
  private readonly routerSubscription: Subscription;

  constructor(
    private appService: AppService,
    private router: Router
  ) {
    this.alertsSubscription = appService.alerts$.subscribe(alert => {
      this.alerts.push(alert);
    });
    this.routerSubscription = router.events.subscribe(event => {
      if (event instanceof NavigationEnd) {
        this.alerts = [];
      }
    });
  }

  ngOnInit() {
    this.appService.setInitialData();
  }

  ngOnDestroy() {
    if (this.alertsSubscription) {
      this.alertsSubscription.unsubscribe();
    }
    if (this.routerSubscription) {
      this.routerSubscription.unsubscribe();
    }
  }

  alertClosed(dismissedAlert: Alert): void {
    this.alerts = this.alerts.filter(alert => alert !== dismissedAlert);
  }
}
