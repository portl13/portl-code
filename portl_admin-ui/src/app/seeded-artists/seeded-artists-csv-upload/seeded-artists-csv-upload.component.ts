import { Component, ViewChild } from '@angular/core';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { SeededArtistsService } from '../seeded-artists.service';
import { ImportResults } from './import-results.type';
import { AppService } from '../../app.service';

@Component({
  selector: 'app-seeded-artists-csv-upload',
  templateUrl: './seeded-artists-csv-upload.component.html',
  styleUrls: ['./seeded-artists-csv-upload.component.scss']
})
export class SeededArtistsCsvUploadComponent {

  title = 'Upload CSV';

  @ViewChild('fileInput')
  fileInput: HTMLInputElement;

  uploadError: string;
  selectedFile: File;

  constructor(
    private appService: AppService,
    public bsModalRef: BsModalRef,
    private seededArtistsService: SeededArtistsService) { }

  fileChangeEvent(event: any): void {
    this.uploadError = null;
    this.selectedFile = event.target.files[0];
  }

  canSubmit(): boolean {
    return !!this.selectedFile;
  }

  onSubmit() {
    this.seededArtistsService
      .bulkCreateCSV(this.selectedFile)
      .toPromise()
      .then((response: ImportResults) => {
        this.bsModalRef.hide();
        this.seededArtistsService.updateSeededArtistsList();
        this.appService.postAlert({
          type: 'success',
          msg: `Success! Uploaded ${response.receivedCount} rows. Inserted ${response.insertedCount} records.`
        });
      })
      .catch((err) => {
        console.log(err);
        this.uploadError = err.error;
      });
  }

}
