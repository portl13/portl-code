import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { SeededArtistsCsvUploadComponent } from './seeded-artists-csv-upload.component';

describe('SeededArtistsCsvUploadComponent', () => {
  let component: SeededArtistsCsvUploadComponent;
  let fixture: ComponentFixture<SeededArtistsCsvUploadComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ SeededArtistsCsvUploadComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(SeededArtistsCsvUploadComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
