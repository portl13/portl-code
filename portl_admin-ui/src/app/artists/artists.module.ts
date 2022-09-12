import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormsModule } from '@angular/forms';
import { ModalModule } from 'ngx-bootstrap/modal';
import { NgxDatatableModule } from '@swimlane/ngx-datatable';
import { PaginationModule } from 'ngx-bootstrap/pagination';

import { ArtistsRoutingModule } from './artists-routing.module';

import { ArtistsService } from './artists.service';

import { ArtistsComponent } from './artists.component';
import { ArtistFormComponent } from './artist-form/artist-form.component';
import { ProgressbarModule } from 'ngx-bootstrap/progressbar';
import { ImageCropperModule } from 'ngx-image-cropper';
import { ArtistsCsvUploadComponent } from './artists-csv-upload/artists-csv-upload.component';

@NgModule({
  imports: [
    CommonModule,
    ReactiveFormsModule,
    FormsModule,
    ModalModule.forRoot(),
    ArtistsRoutingModule,
    NgxDatatableModule,
    PaginationModule.forRoot(),
    ProgressbarModule.forRoot(),
    ImageCropperModule,
  ],
  declarations: [
    ArtistsComponent,
    ArtistFormComponent,
    ArtistsCsvUploadComponent
  ],
  providers: [ ArtistsService ],
  entryComponents: [ ArtistFormComponent, ArtistsCsvUploadComponent ]
})
export class ArtistsModule { }
