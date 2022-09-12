import { Injectable } from '@angular/core';
import { ConfigService } from './config.service';

export const GOOGLE_MAPS_SCRIPT = 'googleMaps';

interface ScriptStatus {
  loaded: boolean;
  src: string;
}

export interface LoadResult {
  script: string;
  loaded: boolean;
  status: string;
}

// Inspired by http://www.lukasjakob.com/how-to-dynamically-load-external-scripts-in-angular/
@Injectable()
export class ScriptLoadingService {

  private scripts: {[name: string]: ScriptStatus} = {};

  constructor(configService: ConfigService) {
    const googleMapsAPIKey = configService.getConfig('googleMapsAPIKey');
    this.scripts[GOOGLE_MAPS_SCRIPT] = {
      src: `https://maps.googleapis.com/maps/api/js?key=${googleMapsAPIKey}&libraries=places&language=en`,
      loaded: false
    };
  }

  loadScript(name: string): Promise<LoadResult> {
    return new Promise((resolve, reject) => {
      // resolve if already loaded
      if (this.scripts[name].loaded) {
        resolve({script: name, loaded: true, status: 'Already Loaded'});
      } else {
        // load script
        const script: HTMLScriptElement = document.createElement('script');
        script.type = 'text/javascript';
        script.src = this.scripts[name].src;
        script.onload = () => {
          this.scripts[name].loaded = true;
          resolve({script: name, loaded: true, status: 'Loaded'});
        };
        script.onerror = (error: any) => resolve({script: name, loaded: false, status: 'Error'});
        // finally append the script tag in the DOM
        document.getElementsByTagName('head')[0].appendChild(script);
      }
    });
  }

}
