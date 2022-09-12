export interface Artist {
  name: string;
  imageUrl: string;
  description?: string;
  url?: string;
  id: string;
}

export const ARTIST = 'artist';

export interface ArtistParams {
  page?: number;
  pageSize?: number;
  ordering?: string;
}
