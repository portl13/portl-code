import { Component, OnInit, OnDestroy, ViewChild, TemplateRef } from '@angular/core';
import { ActivatedRoute, Router, ParamMap } from '@angular/router';
import { BsModalService } from 'ngx-bootstrap/modal';

import { EventFormComponent } from './event-form/event-form.component';

import { EventsService } from './events.service';

import { Event } from './event.type';

import { Subscription } from 'rxjs/Subscription';

import { PortlTable } from '../shared/portl-table';
import { EventsCsvUploadComponent } from './events-csv-upload/events-csv-upload.component';
import { FormBuilder } from '@angular/forms';

@Component({
  selector: 'app-events',
  templateUrl: './events.component.html',
  styleUrls: ['./events.component.scss']
})

export class EventsComponent extends PortlTable implements OnInit, OnDestroy {
  @ViewChild('dateTmpl') dateTmpl: TemplateRef<any>;
  @ViewChild('artistTmpl') artistTmpl: TemplateRef<any>;
  @ViewChild('venueTmpl') venueTmpl: TemplateRef<any>;
  rows: Event[];
  eventsSub: Subscription;
  sortsDefault = { ordering: '-startDateTime' };

  constructor(private eventsService: EventsService,
              private modalService: BsModalService,
              fb: FormBuilder,
              route: ActivatedRoute,
              router: Router) { super(route, fb, router); }

  openCSVDialog() {
    this.bsModalRef = this.modalService.show(EventsCsvUploadComponent, {});
  }

  openModal(event: Event | null) {
    if (event) {
      this.eventsService.getEventDetail(event.id).subscribe((freshEvent: Event) => {
        // TODO: support multiple categories in admin ui
        if (freshEvent.categories.length > 0) {
          freshEvent.category = freshEvent.categories[0];
        }
        const initialState = { event: freshEvent, title: 'Edit Event' };
        this.bsModalRef = this.modalService.show(EventFormComponent, {initialState});
      });
    } else {
      const initialState = { title: 'Create New Event'};
      this.bsModalRef = this.modalService.show(EventFormComponent, {initialState});
    }
  }

  getEvents() {
    this.eventsService.getEvents(this.queryParameters).subscribe(({ results, totalItems }) => {
      this.totalItems = totalItems;
      this.rows = results.map(e => {
        // TODO: this map should go away once we support multiple categories in admin ui
        e.category = e.categories.length > 0 ? e.categories[0] : null;
        return e;
      });
    });
  }

  ngOnInit() {
    this.columns = [
      { name: 'Start Date/Time', prop: 'startDateTime', cellTemplate: this.dateTmpl },
      { name: 'Event Title', prop: 'title' },
      // { name: 'Artist', prop: 'artist', cellTemplate: this.artistTmpl },
      // { name: 'Venue', prop: 'venue', cellTemplate: this.venueTmpl },
      { name: 'Category', prop: 'category' },
      { name: 'UUID', prop: 'id' },
      { name: '', prop: '', cellTemplate: this.actionTmpl }
    ];

    this.eventsSub = this.eventsService.updateEventsSubscription.subscribe(
      res => this.getEvents()
    );

    this.routeSub = this.route.queryParamMap.subscribe((paramMap: ParamMap) => {
      this.updateFilters(paramMap);
      this.getEvents();

      this.mapParamFiltersToTable();
    });
  }

  ngOnDestroy() {
    this.eventsSub.unsubscribe();
    this.routeSub.unsubscribe();
  }
}
