import { ValidatorFn, AbstractControl } from '@angular/forms';

import isUrl from 'validator/lib/isURL';

export class PORTLValidators {
  static url(): ValidatorFn {
    return (control: AbstractControl) => {
      return isUrl(control.value) ? null : { isUrl: false };
    };
  }
}
