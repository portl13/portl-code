import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';

import { SeededArtistsComponent } from './seeded-artists.component';

const routes: Routes = [
  {
    path: '',
    component: SeededArtistsComponent
  }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule],
})
export class SeededArtistsRoutingModule { }
