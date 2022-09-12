/*tslint:disable:curly*/
import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { SeededArtistsService } from '../seeded-artists.service';

import { BsModalRef } from 'ngx-bootstrap/modal/bs-modal-ref.service';

import { SeededArtist } from '../seeded-artist.type';

@Component({
  selector: 'app-seeded-artist-form',
  templateUrl: './seeded-artist-form.component.html',
})

export class SeededArtistFormComponent implements OnInit {
  title: string;
  seededArtist: SeededArtist;
  seededArtistForm: FormGroup;

  get nameField() { return this.seededArtistForm.get('name'); }

  constructor(public bsModalRef: BsModalRef,
              private seededArtistsService: SeededArtistsService,
              private fb: FormBuilder) {}

  canSubmit(): boolean {
    // form.touched doesn't catch the case where the user has added an image
    return this.seededArtistForm.touched && this.seededArtistForm.valid;
  }

  onSubmit() {
    const afterSave = () => {
      this.seededArtistsService.updateSeededArtistsList();
      this.bsModalRef.hide();
    };

    const seededArtistValue = this.seededArtistFromForm;
    if (this.seededArtist) {
      this.seededArtistsService.updateSeededArtist(this.seededArtist.id, seededArtistValue).subscribe(afterSave);
    } else {
      this.seededArtistsService.createSeededArtist(seededArtistValue).subscribe(afterSave);
    }
  }

  deleteSeededArtist() {
    this.seededArtistsService.deleteSeededArtist(this.seededArtist.id).subscribe(_ => {
      this.seededArtistsService.updateSeededArtistsList();
      this.bsModalRef.hide();
    }, error => {
      // TODO: handle error
    });
  }

  get seededArtistFromForm() {
    const formValue = this.seededArtistForm.value;

    return {
      id: formValue.id,
      name: formValue.name,
    };
  }

  createForm(seededArtist) {
    this.seededArtistForm = this.fb.group({
      id: [seededArtist && seededArtist.id || null],
      name: [seededArtist && seededArtist.name || '', Validators.required],
    });
  }

  ngOnInit() {
    this.createForm(this.seededArtist);
  }
}
