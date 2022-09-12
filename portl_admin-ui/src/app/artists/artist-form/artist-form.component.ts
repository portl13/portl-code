/*tslint:disable:curly*/
import { Component, OnInit, ViewChild } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { ArtistsService } from '../artists.service';

import { BsModalRef } from 'ngx-bootstrap/modal/bs-modal-ref.service';

import { guid } from '../../shared/guid';

import { Artist } from '../artist.type';
import { FileUploadService, UploadStatus } from '../../shared/file-upload.service';
import { ImageCroppedEvent } from 'ngx-image-cropper';
import { PORTLValidators } from '../../shared/portl-validators';

@Component({
  selector: 'app-artist-form',
  templateUrl: './artist-form.component.html',
  styleUrls: ['./artist-form.component.scss']
})

export class ArtistFormComponent implements OnInit {
  title: string;
  artist: Artist;
  artistForm: FormGroup;

  get nameField() { return this.artistForm.get('name'); }
  get imageUrl() { return this.artistForm.get('imageUrl'); }
  get url() { return this.artistForm.get('url'); }

  @ViewChild('imageField')
  imageField;

  // TODO : Factor out image-related things from this and event form.
  uploadFilename = '';
  uploadFile = null;
  imageUploadStatus?: UploadStatus;
  imageUploadError: string;
  imageChangedEvent: any = '';
  croppedImage: File = null;

  constructor(public bsModalRef: BsModalRef,
              private artistsService: ArtistsService,
              private fb: FormBuilder,
              private fileUploadService: FileUploadService) {}

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
    // form.touched doesn't catch the case where the user has added an image
    const hasImage = this.croppedImage || (this.artist && this.artist.imageUrl);
    return (this.artistForm.touched || this.croppedImage) && hasImage && this.artistForm.valid && !this.imageUploadError;
  }

  onSubmit() {
    const afterSave = () => {
      this.artistsService.updateArtistsList();
      this.bsModalRef.hide();
    };
    const saveArtist = () => {
      const artistValue = this.artistFromForm;
      if (this.artist) {
        this.artistsService.updateArtist(this.artist.id, artistValue).subscribe(afterSave);
      } else {
        this.artistsService.createArtist(artistValue).subscribe(afterSave);
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
          saveArtist
        );
    } else {
      saveArtist();
    }
  }

  deleteArtist() {
    this.artistsService.deleteArtist(this.artist.id).subscribe(_ => {
      this.artistsService.updateArtistsList();
      this.bsModalRef.hide();
    }, error => {
      // TODO: handle error
    });
  }

  get artistFromForm() {
    const formValue = this.artistForm.value;

    return {
      id: formValue.id,
      name: formValue.name,
      imageUrl: this.imageUploadStatus && this.imageUploadStatus.publicURL || formValue.imageUrl,
      description: formValue.description,
      url: formValue.url,
    };
  }

  createForm(artist) {
    this.artistForm = this.fb.group({
      id: [artist && artist.id || guid()],
      name: [artist && artist.name || '', Validators.required],
      imageUrl: [artist && artist.imageUrl || ''],
      description: [artist && artist.description || ''],
      url: [artist && artist.url || '', PORTLValidators.url()]
    });
  }

  ngOnInit() {
    this.createForm(this.artist);
  }
}

interface ImageValidationErrors {
  error: string;
}
