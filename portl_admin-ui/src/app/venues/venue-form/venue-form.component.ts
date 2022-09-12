import { Component, OnInit, AfterViewInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { VenuesService } from '../venues.service';

import { BsModalRef } from 'ngx-bootstrap/modal/bs-modal-ref.service';

import { Venue } from '../venue.type';
import { Address } from 'ngx-google-places-autocomplete/objects/address';
import { AddressComponent } from 'ngx-google-places-autocomplete/objects/addressComponent';
import { ScriptLoadingService, GOOGLE_MAPS_SCRIPT } from '../../shared/script-loading.service';
import { PORTLValidators } from '../../shared/portl-validators';

@Component({
  selector: 'app-venue-form',
  templateUrl: './venue-form.component.html',
  styleUrls: ['./venue-form.component.scss']
})
export class VenueFormComponent implements OnInit, AfterViewInit {
  title: string;
  venue: Venue;
  venueForm: FormGroup;

  // Don't apply ngx-google-places-autocomplete directive to name field until maps script is loaded.
  mapsLibraryLoaded = false;

  get nameField() { return this.venueForm.get('name'); }
  get zipCode() { return this.venueForm.get('zipCode'); }
  get location() { return this.venueForm.get('location'); }
  get lat() { return this.location.get('lat'); }
  get lng() { return this.location.get('lng'); }
  get url() { return this.venueForm.get('url'); }

  constructor(public bsModalRef: BsModalRef,
              private venuesService: VenuesService,
              private scriptService: ScriptLoadingService,
              private fb: FormBuilder) {}

  googlePlacesAutocompleteOptions = {
    types: ['establishment']
  };

  handleAddressChange(address: Address) {
    this.venueForm.patchValue({
      name: address.name,
      location: {
        lat: address.geometry.location.lat(),
        lng: address.geometry.location.lng(),
      },
      street: this.getValue(address, 'street'),
      street2: this.getValue(address, 'street2'),
      city: this.getValue(address, 'city'),
      state: this.getValue(address, 'state'),
      country: this.getValue(address, 'country'),
      zipCode: this.getValue(address, 'zipCode'),
      url: address.website || address.url
    });
  }

  onSubmit() {
    if (this.venueForm.valid) {

      if (this.venue) {
        this.venuesService.updateVenue(this.venue.id, this.venueFromForm).subscribe(_ => {
          this.venuesService.updateVenuesList();
          this.bsModalRef.hide();
        }, error => {
          // TODO: handle error
        });
      } else {
        this.venuesService.createVenue(this.venueFromForm).subscribe(_ => {
          this.venuesService.updateVenuesList();
          this.bsModalRef.hide();
        }, error => {
          // TODO: handle error
        });
      }
    }
  }

  validateLocation(field: string, value) {
    if (value.indexOf('.') === -1) {
      this[field].setErrors({'precision': true});
      return;
    } else {
      const digits = value.split('.')[1];
      digits.length > 1
        ? this[field].setErrors(null)
        : this[field].setErrors({'precision': true});

      return;
    }
  }

  deleteVenue() {
    this.venuesService.deleteVenue(this.venue.id).subscribe(_ => {
      this.venuesService.updateVenuesList();
      this.bsModalRef.hide();
    }, error => {
      // TODO: handle error
    });
  }

  createForm(venue) {
    this.venueForm = this.fb.group({
      name: [venue && venue.name || '', Validators.required],
      location: this.fb.group({
        lat: [venue && venue.location && venue.location.lat || null, Validators.required],
        lng: [venue && venue.location && venue.location.lng || null, Validators.required],
      }),
      street: [venue && venue.address && venue.address.street || ''],
      street2: [venue && venue.address && venue.address.street2 || ''],
      city: [venue && venue.address && venue.address.city || ''],
      state: [venue && venue.address && venue.address.state || ''],
      country: [venue && venue.address && venue.address.country || ''],
      zipCode: [venue && venue.address && venue.address.zipCode || '', Validators.compose([Validators.minLength(5),
                                      Validators.maxLength(5), Validators.pattern(/^\d+$/)])],
      url: [venue && venue.url || '', PORTLValidators.url()]
    });
  }

  ngOnInit() {
    this.createForm(this.venue);
  }

  ngAfterViewInit(): void {
    this.scriptService.loadScript(GOOGLE_MAPS_SCRIPT).then((result) => {
      if (!result.loaded) {
        console.error(`Failed to load ${GOOGLE_MAPS_SCRIPT}: ${result.status}`);
      }
      this.mapsLibraryLoaded = result.loaded;
    });
  }

  private get venueFromForm(): Venue {
    const formValue = this.venueForm.value;

    return {
      id: this.venue && this.venue.id || null,
      name: formValue.name,
      url: formValue.url,
      location: {
        lat: formValue.location.lat,
        lng: formValue.location.lng
      },
      address: {
        street: formValue.street,
        street2: formValue.street2,
        city: formValue.city,
        state: formValue.state,
        country: formValue.country,
        zipCode: formValue.zipCode
      }
    };
  }

  /**
   * Find the first address component of the given type.
   */
  private findComponent(address: Address, type: AddressComponentType): AddressComponent {
    return address.address_components.find(c => c.types.indexOf(type) >= 0);
  }

  /**
   * Get a value for our form from address data received back from the Google ngx-google-places-autocomplete widget.
   */
  private getValue(address: Address, fieldName: VenueFormFieldName): string {
    const fieldNameMapping: {[fieldName: string]: AddressComponentType[]} = {
      'street': ['street_number', 'route'],
      'street2': ['subpremise'],
      'city': ['locality'],
      'state': ['administrative_area_level_1'],
      'country': ['country'],
      'zipCode': ['postal_code'],
    };

    return fieldNameMapping[fieldName].map(f => {
      const component = this.findComponent(address, f);
      return component ? component.long_name : '';
    }).join(' ');
  }

}

type AddressComponentType =
  'street_number' | 'route' | 'subpremise' | 'locality' | 'administrative_area_level_1' | 'country' | 'postal_code';
type VenueFormFieldName = 'street' | 'street2' | 'city' | 'state' | 'country' | 'zipCode';
