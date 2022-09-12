import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';

const routes: Routes = [
  {
    path: '',
    redirectTo: 'events',
    pathMatch: 'full',
  },
  {
    path: 'events',
    loadChildren: 'app/events/events.module#EventsModule'
  },
  {
    path: 'artists',
    loadChildren: 'app/artists/artists.module#ArtistsModule'
  },
  {
    path: 'venues',
    loadChildren: 'app/venues/venues.module#VenuesModule'
  },
  {
    path: 'seeded-artists',
    loadChildren: 'app/seeded-artists/seeded-artists.module#SeededArtistsModule'
  },
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule],
})
export class AppRoutingModule { }
