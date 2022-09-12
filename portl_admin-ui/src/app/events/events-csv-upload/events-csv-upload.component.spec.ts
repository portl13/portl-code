import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { EventsCsvUploadComponent } from './events-csv-upload.component';

describe('EventsCsvUploadComponent', () => {
  let component: EventsCsvUploadComponent;
  let fixture: ComponentFixture<EventsCsvUploadComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ EventsCsvUploadComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(EventsCsvUploadComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
