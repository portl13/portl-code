/*tslint:disable:forin curly*/
import { Injectable } from '@angular/core';

import { LocalStorageService } from 'angular-2-local-storage';

import { Artist } from '../artists/artist.type';
import { Event } from '../events/event.type';
import { Venue } from '../venues/venue.type';

type EntityName = 'artist' | 'event' | 'venue';

@Injectable()
export class LocalStorageAPIService {

  constructor(private localStorageService: LocalStorageService) {}

  getAllData() {
    return (<any>this.localStorageService.get('appData'));
  }

  setData(name: string, data: any) {
    this.localStorageService.set(name, data);
  }

  getList<EntityType, ParamType>(dataName: EntityName, params: ParamType): EntityType[] {
    const tupleList = [];
    for (const key in params) { tupleList.push([key, params[key]]); }
    const filterString = tupleList.map(tuple => tuple.join('=')).join('&');

    // const path = `realapi/${dataName}?${filterString}`;
    const data = this.getAllData();

    return data[dataName];
  }

  update<EntityType>(dataName: EntityName, data: EntityType) {
    const appData = this.getAllData();
    let entityArray = appData[dataName];

    const entityIndex = entityArray.findIndex(e => e.id === (<any>data).id);
    if (entityIndex === -1) return;

    entityArray = [
        ...entityArray.slice(0, entityIndex),
        data,
        ...entityArray.slice(entityIndex + 1)
    ];

    appData[dataName] = entityArray;
    this.setData('appData', appData);
  }

  create<EntityType>(dataName: EntityName, data: EntityType) {
    const appData = this.getAllData();

    let entityArray = appData[dataName];
    entityArray = [...entityArray, data];

    appData[dataName] = entityArray;
    this.setData('appData', appData);
  }

  delete<EntityType>(dataName: EntityName, data: EntityType) {
    const appData = this.getAllData();
    let entityArray = appData[dataName];

    const entityIndex = entityArray.findIndex(e => e.id === (<any>data).id);
    if (entityIndex === -1) return;

    entityArray = [
        ...entityArray.slice(0, entityIndex),
        ...entityArray.slice(entityIndex + 1)
    ];

    appData[dataName] = entityArray;
    this.setData('appData', appData);
  }

}
