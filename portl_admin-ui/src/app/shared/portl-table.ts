import { TemplateRef, ViewChild } from '@angular/core';
import { ActivatedRoute, Router, NavigationExtras, ParamMap } from '@angular/router';
import { Subscription } from 'rxjs/Subscription';

import { BsModalRef } from 'ngx-bootstrap/modal/bs-modal-ref.service';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';

export class PortlTable {
  @ViewChild('actionTmpl') actionTmpl: TemplateRef<any>;
  columns: any[];
  bsModalRef: BsModalRef;
  sortsDefault = { ordering: '-name' };
  paginationDefault = { page: 1, pageSize: 50 };
  filterDefault = {};
  filterBy = 'q';
  totalItems = 0;
  currentPage = 1;  // 1-indexed in app, mapped to 0-indexed for API calls in PageIndexInterceptor.
  queryParameters: any = Object.assign({}, this.paginationDefault, this.sortsDefault, this.filterDefault);
  routeSub: Subscription;
  sorts = [];
  searchForm: FormGroup;

  constructor(public route: ActivatedRoute,
              private fb: FormBuilder,
              private router: Router) {
    this.initSearchForm();
  }

  initSearchForm() {
    this.searchForm = this.fb.group({
      search: ['']
    });
  }

  updateUrl(key: string, value: string | number, moreKeys: { [key: string]: string | number } = {}) {
    const navigationExtras: NavigationExtras = {
        queryParams: Object.assign({}, this.queryParameters, { [key]: value }, moreKeys),
        queryParamsHandling: 'merge',
    };

    const url = this.router.url.split('?')[0];

    this.router.navigate([url], navigationExtras);
    return false;
  }

  updateFilters(queryParams: ParamMap) {
    this.queryParameters = Object.assign({}, this.paginationDefault, this.sortsDefault, this.filterDefault);

    queryParams.keys.forEach((key: string) => {
      this.queryParameters[key] = queryParams.get(key);
    });

    this.currentPage = parseInt(queryParams.get('page') || '1', 10);
  }

  onSort(event) {
    let filter = event.sorts[0].prop;

    if (event.newValue === 'desc') {
      if (filter.indexOf(',') !== -1) {

        const filters = [];
        filter.split(',').forEach(f => {
          filters.push(`-${f}`);
        });
        filter = filters.join(',');

      } else {
        filter = `-${filter}`;
      }
    }

    this.updateUrl('ordering', filter, {'page': 1});
  }

  onFilter(filterString) {
    this.updateUrl(this.filterBy, filterString || undefined);
  }

  onSearchSubmit() {
    this.onFilter(this.searchForm.get('search').value);
  }

  mapParamFiltersToTable() {
    if (this.queryParameters.ordering) {
      let filter;
      let dir;

      if (this.queryParameters.ordering.indexOf('-') !== -1) {
        filter = this.queryParameters.ordering.slice(1, this.queryParameters.ordering.length);
        dir = 'desc';
      } else {
        filter = this.queryParameters.ordering;
        dir = 'asc';
      }

      this.sorts = [{
        prop: filter,
        dir: dir
      }];
    }
  }
}
