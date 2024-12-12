import { Component, Inject, PLATFORM_ID } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { environment } from '../environments/environment';
import { AuthService } from './services/auth.service';
import { DOCUMENT, isPlatformBrowser } from '@angular/common';
import { HeaderComponent } from './component/children/header/header.component';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet,HeaderComponent],
  templateUrl: './app.component.html',
  styleUrl: './app.component.css'
})
export class AppComponent {
  title = 'Time Tracking -' + environment.ENV;
  isBrowser: any;
  
  constructor(private readonly authService : AuthService,
    @Inject(DOCUMENT) private readonly dom: Document,
    @Inject(PLATFORM_ID) private readonly platformId: Object) {
    this.isBrowser = isPlatformBrowser(platformId);
    if (this.isBrowser) {
      let location = window.location.search;
      let urlSearchParams = new URLSearchParams(location);
      let params = Object.fromEntries(urlSearchParams?.entries()); 
      this.authService.login(params['access_token'],params['id_token'],params['refresh_token']);
    }
  }
}
