import { HttpEvent, HttpHandler, HttpInterceptor, HttpRequest } from '@angular/common/http';
import { Observable } from 'rxjs/Observable';
import { ConfigService } from '../shared/config.service';
import { Injectable } from '@angular/core';

/**
 * Updates `page` parameter of outgoing API requests to be 0-indexed.
 *
 * The API expects the `page` parameter to be 0-indexed, but this application uses 1-indexed pages.
 */
@Injectable()
export class PageIndexInterceptor implements HttpInterceptor {

  private _apiURLRegex: RegExp;

  constructor(private configService: ConfigService) {}

  get apiURLRegex(): RegExp {
    if (!this._apiURLRegex) {
      try {
        this._apiURLRegex = new RegExp(`^${this.configService.getConfig('apiUrl')}[^?]*\\?`);
      } catch (e) {
        if (e instanceof TypeError) {
          // config not yet loaded
        } else {
          throw e;
        }
      }
    }
    return this._apiURLRegex;
  }

  intercept(req: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    console.log('interceptor');

    if (this.apiURLRegex) {
      const query = req.url.replace(this.apiURLRegex, ''),
        params = new URLSearchParams(query);

      if (params.has('page')) {
        const uiPage = parseInt(params.get('page'), 10);
        params.delete('page');
        params.set('page', `${uiPage - 1}`);

        return next.handle(req.clone({
          url: req.url.replace(/\?.*$/, `?${params.toString()}`)
        }));
      }
    }

    return next.handle(req);
  }
}
