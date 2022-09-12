import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormsModule } from '@angular/forms';
import { NgxDatatableModule } from '@swimlane/ngx-datatable';
import { ModalModule } from 'ngx-bootstrap/modal';
import { BsDatepickerModule } from 'ngx-bootstrap/datepicker';
import { TimepickerModule } from 'ngx-bootstrap/timepicker';
import { PaginationModule } from 'ngx-bootstrap/pagination';
import { ProgressbarModule } from 'ngx-bootstrap/progressbar';
import { ImageCropperModule } from 'ngx-image-cropper';
import { LSelect2Module } from 'ngx-select2'

import { EventsRoutingModule } from './events-routing.module';

import { EventsComponent } from './events.component';
import { EventFormComponent } from './event-form/event-form.component';
import { EventsCsvUploadComponent } from './events-csv-upload/events-csv-upload.component';

import { EventsService } from './events.service';

@NgModule({
  imports: [
    CommonModule,
    ReactiveFormsModule,
    FormsModule,
    EventsRoutingModule,
    NgxDatatableModule,
    ModalModule.forRoot(),
    BsDatepickerModule.forRoot(),
    TimepickerModule.forRoot(),
    PaginationModule.forRoot(),
    ProgressbarModule.forRoot(),
    ImageCropperModule,
    LSelect2Module,
  ],
  declarations: [
    EventsComponent,
    EventFormComponent,
    EventsCsvUploadComponent,
  ],
  providers: [ EventsService ],
  entryComponents: [ EventFormComponent, EventsCsvUploadComponent ]
})
export class EventsModule { }
