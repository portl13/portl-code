export interface SeededArtist {
  name: string;
  id: string;
}

export const SEEDED_ARTIST = 'seededArtist';

export interface SeededArtistParams {
  page?: number;
  pageSize?: number;
  ordering?: string;
}
