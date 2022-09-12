import { Component, ViewChild } from '@angular/core';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { ImportResults } from './import-results.type';
import { AppService } from '../../app.service';
import { ArtistsService } from '../artists.service';

@Component({
  selector: 'app-artists-csv-upload',
  templateUrl: './artists-csv-upload.component.html',
})
export class ArtistsCsvUploadComponent {

  title = 'Upload CSV';

  @ViewChild('fileInput')
  fileInput: HTMLInputElement;

  uploadError: string;
  selectedFile: File;

  constructor(
    private appService: AppService,
    public bsModalRef: BsModalRef,
    private artistsService: ArtistsService) { }

  fileChangeEvent(event: any): void {
    this.uploadError = null;
    this.selectedFile = event.target.files[0];
  }

  canSubmit(): boolean {
    return !!this.selectedFile;
  }

  onSubmit() {
    this.artistsService
      .bulkCreateCSV(this.selectedFile)
      .toPromise()
      .then((response: ImportResults) => {
        this.bsModalRef.hide();
        this.artistsService.updateArtistsList();
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
