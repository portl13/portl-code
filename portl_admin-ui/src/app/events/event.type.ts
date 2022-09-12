import { Artist } from '../artists/artist.type';
import { Venue } from '../venues/venue.type';

export interface Event {
  title: string;
  artist?: Artist;
  venue?: Venue;
  timezone: string;
  startDateTime: number;
  endDateTime?: number;
  imageUrl?: string;
  description?: string;
  // TODO: in the future, we'll only be supporting `categories`
  category?: any;
  categories?: any;
  url?: string;
  ticketPurchaseUrl?: string;
  id: string;
}

export const EVENT = 'event';

export interface EventsParams {
  page?: number;
  pageSize?: number;
  ordering?: string;
}
