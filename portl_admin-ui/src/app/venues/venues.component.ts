import { Component, OnInit, OnDestroy, ViewChild, TemplateRef } from '@angular/core';
import { ActivatedRoute, Router, NavigationExtras, ParamMap } from '@angular/router';
import { BsModalService } from 'ngx-bootstrap/modal';

import { VenueFormComponent } from './venue-form/venue-form.component';

import { VenuesService } from './venues.service';

import { Venue } from './venue.type';

import { Subscription } from 'rxjs/Subscription';

import { PortlTable } from '../shared/portl-table';
import { FormBuilder } from '@angular/forms';

@Component({
  selector: 'app-venues',
  templateUrl: './venues.component.html',
  styleUrls: ['./venues.component.scss']
})

export class VenuesComponent extends PortlTable implements OnInit, OnDestroy {
  rows: Venue[];
  venuesSub: Subscription;

  constructor(private venuesService: VenuesService,
              private modalService: BsModalService,
              fb: FormBuilder,
              route: ActivatedRoute,
              router: Router) { super(route, fb, router); }

  openModal(venue: Venue | null) {
    const initialState = {
      venue,
      title: venue !== null ? 'Edit Venue' : 'Create New Venue'
    };
    this.bsModalRef = this.modalService.show(VenueFormComponent, {initialState});
  }

  getVenues() {
    this.venuesService.getVenues(this.queryParameters).subscribe(({ results, totalItems }) => {
      this.totalItems = totalItems;
      this.rows = results;
    });
  }

  ngOnInit() {
    this.columns = [
      { name: 'Venue Name', prop: 'name' },
      { name: 'City', prop: 'address.city' },
      { name: 'State', prop: 'address.state' },
      { name: 'UUID', prop: 'id' },
      { name: '', prop: '', cellTemplate: this.actionTmpl }
    ];

    this.venuesSub = this.venuesService.updateVenuesSubscription.subscribe(
      res => this.getVenues()
    );

    this.routeSub = this.route.queryParamMap.subscribe((paramMap: ParamMap) => {
      this.updateFilters(paramMap);
      this.getVenues();

      this.mapParamFiltersToTable();
    });
  }

  ngOnDestroy() {
    this.venuesSub.unsubscribe();
    this.routeSub.unsubscribe();
  }
}
