import { Component, ViewChild } from '@angular/core';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { EventsService } from '../events.service';
import { ImportResults } from './import-results.type';
import { AppService } from '../../app.service';

@Component({
  selector: 'app-events-csv-upload',
  templateUrl: './events-csv-upload.component.html',
  styleUrls: ['./events-csv-upload.component.scss']
})
export class EventsCsvUploadComponent {

  title = 'Upload CSV';

  @ViewChild('fileInput')
  fileInput: HTMLInputElement;

  uploadError: string;
  selectedFile: File;

  constructor(
    private appService: AppService,
    public bsModalRef: BsModalRef,
    private eventsService: EventsService) { }

  fileChangeEvent(event: any): void {
    this.uploadError = null;
    this.selectedFile = event.target.files[0];
  }

  canSubmit(): boolean {
    return !!this.selectedFile;
  }

  onSubmit() {
    this.eventsService
      .bulkCreateCSV(this.selectedFile)
      .toPromise()
      .then((response: ImportResults) => {
        this.bsModalRef.hide();
        this.eventsService.updateEventsList();
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
