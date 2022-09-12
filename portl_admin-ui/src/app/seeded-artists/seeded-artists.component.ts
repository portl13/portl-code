import { Component, OnInit, OnDestroy, ViewChild, TemplateRef } from '@angular/core';
import { ActivatedRoute, Router, NavigationExtras, ParamMap } from '@angular/router';
import { BsModalService } from 'ngx-bootstrap/modal';

import { Subscription } from 'rxjs/Subscription';

import { PortlTable } from '../shared/portl-table';
import { SeededArtist } from './seeded-artist.type';
import { SeededArtistsService } from './seeded-artists.service';
import { SeededArtistFormComponent } from './seeded-artist-form/seeded-artist-form.component';
import { SeededArtistsCsvUploadComponent } from './seeded-artists-csv-upload/seeded-artists-csv-upload.component';
import { FormBuilder } from '@angular/forms';

@Component({
  selector: 'app-seeded-artists',
  templateUrl: './seeded-artists.component.html',
  styleUrls: ['./seeded-artists.component.scss']
})

export class SeededArtistsComponent extends PortlTable implements OnInit, OnDestroy {
  rows: SeededArtist[];
  seededArtistsSub: Subscription;

  constructor(private seededArtistsService: SeededArtistsService,
              private modalService: BsModalService,
              fb: FormBuilder,
              route: ActivatedRoute,
              router: Router) { super(route, fb, router); }

  openCSVDialog() {
    this.bsModalRef = this.modalService.show(SeededArtistsCsvUploadComponent, {});
  }

  openModal(seededArtist: SeededArtist | null) {
    const initialState = {
      seededArtist,
      title: seededArtist !== null ? 'Edit SeededArtist' : 'Create New SeededArtist'
    };
    this.bsModalRef = this.modalService.show(SeededArtistFormComponent, {initialState});
  }

  getSeededArtists() {
    this.seededArtistsService.getSeededArtists(this.queryParameters).subscribe(({ totalItems, results }) => {
      this.totalItems = totalItems;
      this.rows = results;
    });
  }

  ngOnInit() {
    this.columns = [
      { name: 'SeededArtist Name', prop: 'name', width: 20 },
      { name: 'UUID', prop: 'id' },
      { name: '', prop: '', cellTemplate: this.actionTmpl }
    ];

    this.seededArtistsSub = this.seededArtistsService.updateSeededArtistsSubscription.subscribe(
      res => this.getSeededArtists()
    );

    this.routeSub = this.route.queryParamMap.subscribe((paramMap: ParamMap) => {
      this.updateFilters(paramMap);
      this.getSeededArtists();

      this.mapParamFiltersToTable();
    });
  }

  ngOnDestroy() {
    this.seededArtistsSub.unsubscribe();
    this.routeSub.unsubscribe();
  }
}
