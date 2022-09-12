import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormsModule } from '@angular/forms';
import { ModalModule } from 'ngx-bootstrap/modal';
import { NgxDatatableModule } from '@swimlane/ngx-datatable';
import { PaginationModule } from 'ngx-bootstrap/pagination';
import { SeededArtistsService } from './seeded-artists.service';
import { SeededArtistsComponent } from './seeded-artists.component';
import { SeededArtistsRoutingModule } from './seeded-artists-routing.module';
import { SeededArtistFormComponent } from './seeded-artist-form/seeded-artist-form.component';
import { SeededArtistsCsvUploadComponent } from './seeded-artists-csv-upload/seeded-artists-csv-upload.component';

@NgModule({
  imports: [
    CommonModule,
    ReactiveFormsModule,
    FormsModule,
    ModalModule.forRoot(),
    SeededArtistsRoutingModule,
    NgxDatatableModule,
    PaginationModule.forRoot(),
  ],
  declarations: [
    SeededArtistsComponent,
    SeededArtistFormComponent,
    SeededArtistsCsvUploadComponent
  ],
  providers: [ SeededArtistsService ],
  entryComponents: [ SeededArtistFormComponent, SeededArtistsCsvUploadComponent ]
})
export class SeededArtistsModule { }
