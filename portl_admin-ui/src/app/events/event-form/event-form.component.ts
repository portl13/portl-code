import { Component, OnInit, ViewChild } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { EventsService } from '../events.service';

import { BsModalRef } from 'ngx-bootstrap/modal/bs-modal-ref.service';

import { guid } from '../../shared/guid';
import * as moment from 'moment-timezone-with-data-2010-2020';

import { Event } from '../event.type';
import { Artist } from '../../artists/artist.type';
import { Venue } from '../../venues/venue.type';
import { FileUploadService, UploadStatus } from '../../shared/file-upload.service';
import { ConfigService} from '../../shared/config.service';
import { ImageCroppedEvent } from 'ngx-image-cropper';
import { PORTLValidators } from '../../shared/portl-validators';

@Component({
  selector: 'app-event-form',
  templateUrl: './event-form.component.html',
  styleUrls: ['./event-form.component.scss']
})

export class EventFormComponent implements OnInit {
  title: string;
  event: Event;
  artists: Artist[];
  venues: Venue[];
  categories: string[];
  eventForm: FormGroup;
  apiUrl: string;

  selectedArtist: any;
  selectedArtistData: any;
  remoteArtistOptions: any = {};
  selectedVenue: any;
  selectedVenueData: any;
  remoteVenueOptions: any = {};
  remoteOptionsTemplate: any = {
    multiple: false,
    minimumInputLength: 1,
    escapeMarkup: function (markup) { return markup; },
    templateResult: this.formatRepo,
    templateSelection: this.formatRepoSelection
  };
  ajaxOptionsTemplate: any = {
    dataType: 'json',
    contentType: "text/json",
    delay: 250,
    data: function(params) {
      return {
        pageSize: 50,
        q: params.term,
        page: params.page
      };
    },
    processResults: function(data, params) {
      params.page = params.page || 1;

      return {
        results: data.results,
        pagination: {
          more: data.results.length === 50,
        }
      };
    },
    cache: true
  };

  usTzNames = [
    'America/Denver',
    'Pacific/Honolulu',
    'America/New_York',
    'America/Adak',
    'America/Los_Angeles',
    'America/Phoenix',
    'America/Anchorage',
    'America/Chicago',
  ];

  formSelectArtist(artist: Artist) {
    this.eventForm.controls.artist.setValue(artist);
    this.eventForm.markAsTouched();
  }

  formSelectVenue(venue: Venue) {
    this.eventForm.controls.venue.setValue(venue);
    this.eventForm.markAsTouched();
  }

  timezoneOptions = moment.tz.names()
    .filter(name => this.usTzNames.indexOf(name) >= 0)
    .map(name => {
      return {
        name: `${name} (${moment.tz(name).format('z') })`,
        value: name,
      };
    });

  get titleField() { return this.eventForm.get('title'); }
  get timezone() { return this.eventForm.get('timezone'); }
  get startDate() { return this.eventForm.get('startDate'); }
  get startTime() { return this.eventForm.get('startTime'); }
  get imageUrl() { return this.eventForm.get('imageUrl'); }
  get ticketPurchaseUrl() { return this.eventForm.get('ticketPurchaseUrl'); }
  get url() { return this.eventForm.get('url'); }

  @ViewChild('imageField')
  imageField;

  // TODO : Factor out image-related things from this and artist form.
  uploadFilename = '';
  uploadFile = null;
  imageUploadStatus?: UploadStatus;
  imageUploadError: string;
  imageChangedEvent: any = '';
  croppedImage: File = null;

  constructor(public bsModalRef: BsModalRef,
              private eventsService: EventsService,
              private fb: FormBuilder,
              private fileUploadService: FileUploadService,
              private configService: ConfigService,
  ) {}

  get eventFromForm() {
    const formValue = this.eventForm.value;

    return {
      title: formValue.title,
      artistId: formValue.artist && formValue.artist.id,
      venueId: formValue.venue && formValue.venue.id,
      timezone: formValue.timezone,
      startDateTime: this.formatDateTime(formValue.startDate, formValue.startTime),
      endDateTime: this.formatDateTime(formValue.endDate, formValue.endTime),
      imageUrl: this.imageUploadStatus && this.imageUploadStatus.publicURL || formValue.imageUrl,
      description: formValue.description,
      categories: formValue.category ? [formValue.category] : [],
      url: formValue.url,
      ticketPurchaseUrl: formValue.ticketPurchaseUrl,
      id: formValue.id
    };
  }

  formatDateTime(dateValue, timeValue) {
    return (dateValue && timeValue) ? new Date(`${this.formatDate(dateValue)} ${this.formatTime(timeValue)}`).getTime() : null;
  }

  validateMinimumSize(file: File): Promise<ImageValidationErrors | null> {
    return new Promise<ImageValidationErrors>((resolve, reject) => {
      const image = new Image();
      image.onload = function() {
        const im = <HTMLImageElement> this;
        if (im.width < 1242 || im.height < 877) {
          resolve({error: `Image too small (${im.width}x${im.height}, required 1242x877)`});
        } else {
          resolve(null);
        }
      };
      image.src = URL.createObjectURL(file);
    });
  }

  fileChangeEvent(event: any): void {
    const file = event.target.files[0];
    this.clearImageFieldState();
    if (file) {
      this.validateMinimumSize(file).then(errors => {
        if (errors) {
          this.imageUploadError = errors.error;
        } else {
          this.imageChangedEvent = event;
          this.uploadFilename = file.name;
          this.uploadFile = file;
        }
      });
    }
  }
  imageCropped(event: ImageCroppedEvent) {
    this.croppedImage = new File([event.file], this.uploadFilename, {type: 'image/jpeg'});
  }

  clearImageFieldState() {
    // We want to clear all this when the user changes the input value, but we don't want to clear the
    // input in that case.
    this.imageChangedEvent = null;
    this.imageUploadStatus = null;
    this.imageUploadError = null;
    this.croppedImage = null;
    this.uploadFilename = '';
    this.uploadFile = null;
  }

  resetImageField() {
    // We only want to clear the underlying input value if the user presses 'Reset'.
    this.imageField.nativeElement.value = '';
    this.clearImageFieldState();
  }

  canSubmit(): boolean {
    // eventForm.touched doesn't catch the case where the user has added an image
    return (this.eventForm.touched || this.croppedImage) && this.eventForm.valid && !this.imageUploadError;
  }

  onSubmit() {
    const afterSave = () => {
      this.eventsService.updateEventsList();
      this.bsModalRef.hide();
    };
    const saveEvent = () => {
      const eventValue = this.eventFromForm;
      if (this.event) {
        this.eventsService.updateEvent(this.event.id, eventValue).subscribe(afterSave);
      } else {
        this.eventsService.createEvent(eventValue).subscribe(afterSave);
      }
    };

    if (this.croppedImage) {
      this.fileUploadService.uploadFile(this.croppedImage)
        .subscribe(
          status => this.imageUploadStatus = status,
          error => {
              console.log(error);
              this.imageUploadStatus = null;
              this.imageUploadError = 'Error uploading file.';
            },
            saveEvent
        );
    } else {
      saveEvent();
    }
  }

  byDataId(option, modal) {
    if (modal && option) {
      return modal.id === option.id;
    }
    return option === modal;
  }

  getDate(timestamp) {
    const date = new Date(timestamp);
    return date;
  }

  formatDate(date: Date) {
    if (!date) { return ''; }
    const month = date.getMonth() + 1;
    const day = date.getDate();
    const year = date.getFullYear();
    return `${month} ${day} ${year}`;
  }

  formatTime(time: Date) {
    if (!time) { return ''; }
    const hours = time.getHours();
    const minutes = time.getMinutes();
    return `${hours}:${minutes}`;
  }

  deleteEvent() {
    this.eventsService.deleteEvent(this.event.id).subscribe(_ => {
      this.eventsService.updateEventsList();
      this.bsModalRef.hide();
    }, error => {
      // TODO: handle error
    });
  }

  createForm(event) {
    this.eventForm = this.fb.group({
      id: [event && event.id || guid()],
      title: [event && event.title || '', Validators.required],
      artist: [event && event.artist || null],
      venue: [event && event.venue || null],
      timezone: [event && event.timezone || '', Validators.required],
      startDate: [event && event.startDateTime && this.getDate(event.startDateTime) || new Date(), Validators.required],
      startTime: [event && event.startDateTime && this.getDate(event.startDateTime) || new Date(), Validators.required],
      endDate: [event && event.endDateTime && this.getDate(event.endDateTime) || ''],
      endTime: [event && event.endDateTime && this.getDate(event.endDateTime) || ''],
      imageUrl: [event && event.imageUrl || ''],
      description: [event && event.description || ''],
      category: [event && event.category || null],
      url: [event && event.url || '', PORTLValidators.url()],
      ticketPurchaseUrl: [event && event.ticketPurchaseUrl || '', PORTLValidators.url()]
    });
  }

  ngOnInit() {
    this.apiUrl = this.configService.getConfig('apiUrl');

    if (this.event && this.event.artist) {
      this.selectedArtist = this.event.artist;
      this.selectedArtistData = { text: this.event.artist.name, id: this.event.artist.id };
    }
    const ajaxArtistOptions = Object.assign({url: `${this.apiUrl}/artist`}, this.ajaxOptionsTemplate);
    this.remoteArtistOptions = Object.assign({data: [this.selectedArtist], ajax: ajaxArtistOptions}, this.remoteOptionsTemplate);

    if (this.event && this.event.venue) {
      this.selectedVenue = this.event.venue;
      this.selectedVenueData = { text: this.event.venue.name, id: this.event.venue.id };
    }
    const ajaxVenueOptions = Object.assign({url: `${this.apiUrl}/venue`}, this.ajaxOptionsTemplate);
    this.remoteVenueOptions = Object.assign({data: [this.selectedVenue], ajax: ajaxVenueOptions}, this.remoteOptionsTemplate);

    this.eventsService.getArtists().subscribe(({ results }) => {
      this.artists = results
    });
    this.eventsService.getVenues().subscribe(({ results }) => this.venues = results);
    this.categories = this.eventsService.getCategories();
    this.createForm(this.event);
  }

  formatRepo(artistOrVenue) {
    return artistOrVenue.name;
  }

  formatRepoSelection(artistOrVenue) {
    return artistOrVenue.name;
  }
}

interface ImageValidationErrors {
  error: string;
}
