interface Location {
  lat: number;
  lng: number;
}

interface Address {
  street?: string;
  street2?: string;
  city?: string;
  state?: string;
  country?: string;
  zipCode?: string;
}

export interface Venue {
  name: string;
  location: Location;
  address: Address;
  url?: string;
  id?: string;
}

export const VENUE = 'venue';

export interface VenueParams {
  page?: number;
  pageSize?: number;
  ordering?: string;
}
