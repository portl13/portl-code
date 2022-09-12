import { Component, OnDestroy, OnInit } from '@angular/core';
import { ActivatedRoute, ParamMap, Router } from '@angular/router';
import { BsModalService } from 'ngx-bootstrap/modal';

import { ArtistsService } from './artists.service';
import { ArtistFormComponent } from './artist-form/artist-form.component';

import { Artist } from './artist.type';

import { Subscription } from 'rxjs/Subscription';

import { PortlTable } from '../shared/portl-table';
import { FormBuilder } from '@angular/forms';
import { ArtistsCsvUploadComponent } from './artists-csv-upload/artists-csv-upload.component';

@Component({
  selector: 'app-artists',
  templateUrl: './artists.component.html',
  styleUrls: ['./artists.component.scss']
})

export class ArtistsComponent extends PortlTable implements OnInit, OnDestroy {
  rows: Artist[];
  artistsSub: Subscription;

  // TODO: create while filtered?

  constructor(private artistsService: ArtistsService,
              private modalService: BsModalService,
              fb: FormBuilder,
              route: ActivatedRoute,
              router: Router) { super(route, fb, router); }

  openCSVDialog() {
    this.bsModalRef = this.modalService.show(ArtistsCsvUploadComponent, {});
  }

  openModal(artist: Artist | null) {
    const initialState = {
      artist,
      title: artist !== null ? 'Edit Artist' : 'Create New Artist'
    };
    this.bsModalRef = this.modalService.show(ArtistFormComponent, {initialState});
  }

  getArtists() {
    this.artistsService.getArtists(this.queryParameters).subscribe(({ totalItems, results }) => {
      this.totalItems = totalItems;
      this.rows = results;
    });
  }

  ngOnInit() {
    this.columns = [
      { name: 'Artist Name', prop: 'name', width: 20 },
      { name: 'UUID', prop: 'id' },
      { name: '', prop: '', cellTemplate: this.actionTmpl }
    ];

    this.artistsSub = this.artistsService.updateArtistsSubscription.subscribe(
      res => this.getArtists()
    );

    this.routeSub = this.route.queryParamMap.subscribe((paramMap: ParamMap) => {
      this.updateFilters(paramMap);
      this.getArtists();

      this.mapParamFiltersToTable();
    });
  }

  ngOnDestroy() {
    this.artistsSub.unsubscribe();
    this.routeSub.unsubscribe();
  }
}
