import { enableProdMode } from '@angular/core';
import { platformBrowserDynamic } from '@angular/platform-browser-dynamic';

import { AppModule } from './app/app.module';
import { environment } from './environments/environment';

import cssVars from 'css-vars-ponyfill';

cssVars({
  include: 'style,link[rel="stylesheet"]:not([href*="//"])',
  onlyLegacy: true,
  watch: true,
  onComplete(cssText, styleNode, cssVariables) {
    console.log('cssText:', cssText);
  }
});

if (environment.production) {
  enableProdMode();
}

platformBrowserDynamic()
  .bootstrapModule(AppModule)
  .catch(err => console.log(err));
