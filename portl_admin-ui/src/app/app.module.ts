import { BrowserModule } from '@angular/platform-browser';
import { NgModule, APP_INITIALIZER } from '@angular/core';
import { HTTP_INTERCEPTORS, HttpClientModule } from '@angular/common/http';
import { NgxDatatableModule } from '@swimlane/ngx-datatable';
import { LocalStorageModule } from 'angular-2-local-storage';
import { AlertModule } from 'ngx-bootstrap/alert';

import { AppRoutingModule } from './app-routing.module';

import { LocalStorageAPIService } from './shared/local-storage-api.service';
import { AppService } from './app.service';

import { AppComponent } from './app.component';
import { RemoteApiService } from './shared/remote-api.service';
import { ConfigService } from './shared/config.service';
import { ScriptLoadingService } from './shared/script-loading.service';
import { FileUploadService } from './shared/file-upload.service';
import { PageIndexInterceptor } from './interceptors/PageIndexInterceptor';

@NgModule({
  declarations: [
    AppComponent
  ],
  imports: [
    AlertModule.forRoot(),
    BrowserModule,
    HttpClientModule,
    NgxDatatableModule,
    LocalStorageModule.withConfig({
        prefix: 'prt',
        storageType: 'localStorage',
    }),
    AppRoutingModule
  ],
  providers: [
    AppService,
    ConfigService,
    {
      provide: APP_INITIALIZER,
      useFactory: (config: ConfigService) => () => config.load(),
      deps: [ConfigService],
      multi: true
    },
    FileUploadService,
    LocalStorageAPIService,
    RemoteApiService,
    ScriptLoadingService,
    { provide: HTTP_INTERCEPTORS, useClass: PageIndexInterceptor, multi: true },
  ],
  bootstrap: [ AppComponent ]
})
export class AppModule { }
