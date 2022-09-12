import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormsModule } from '@angular/forms';
import { ModalModule } from 'ngx-bootstrap/modal';
import { NgxDatatableModule } from '@swimlane/ngx-datatable';
import { PaginationModule } from 'ngx-bootstrap/pagination';
import { GooglePlaceModule } from 'ngx-google-places-autocomplete';

import { VenuesRoutingModule } from './venues-routing.module';

import { VenuesService } from './venues.service';

import { VenuesComponent } from './venues.component';
import { VenueFormComponent } from './venue-form/venue-form.component';

@NgModule({
  imports: [
    CommonModule,
    ReactiveFormsModule,
    FormsModule,
    ModalModule.forRoot(),
    PaginationModule.forRoot(),
    VenuesRoutingModule,
    NgxDatatableModule,
    GooglePlaceModule,
  ],
  declarations: [
    VenuesComponent,
    VenueFormComponent
  ],
  providers: [ VenuesService ],
  entryComponents: [ VenueFormComponent ]
})
export class VenuesModule { }
