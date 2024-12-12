import { DOCUMENT, isPlatformBrowser } from '@angular/common';
import { Inject, Injectable, PLATFORM_ID } from '@angular/core';
import { JwtHelperService } from '@auth0/angular-jwt';
import { BehaviorSubject, Observable } from 'rxjs';

export interface User {
  fullname: string;
  cwid: string;
  firstname: string;
  lastname: string;
  email: string;
  roles: string[];
}

@Injectable({
  providedIn: 'root',
})
export class AuthService {
  private readonly currentUserSubject: BehaviorSubject<User | null>;
  public currentUser: Observable<User | null>;
  decodedToken: any;
  isBrowser: boolean;
  location: Location | undefined;

  constructor ( @Inject(DOCUMENT) private readonly dom: Document,
  @Inject(PLATFORM_ID) private readonly platformId: Object) {
  this.isBrowser = isPlatformBrowser(platformId);
  if (this.isBrowser) {
    this.location = window.location;  
  }
    this.currentUserSubject = new BehaviorSubject<User | null>(null);
    this.currentUser = this.currentUserSubject.asObservable();
  }

  login(accessToken: string = "",idToken: string = "",refreshToken: string = ""): void {
    // For demo purposes, assume authentication is successful.
    // Login Method tobe implemented
    let user: User;
    if(this.location!==undefined && accessToken != "" ){      
      sessionStorage.setItem('access_token', accessToken);
      sessionStorage.setItem('id_token', idToken);
      sessionStorage.setItem('refresh_token', refreshToken);
      const helper = new JwtHelperService();
      this.decodedToken = helper.decodeToken( accessToken );
      user = {  //For Testing purpose and untill token is configured values hardcoded
        fullname: this.decodedToken.name,
        cwid: this.decodedToken['https://bayer.com/cwid'],
        lastname: this.decodedToken.family_name,
        firstname: this.decodedToken.given_name,
        email: this.decodedToken.unique_name,
        roles: ['SSTUser','bulkUploadUser','XPWDUser'], //'SSTUser','bulkUploadUser','XPWDUser' // to be populated from token details
      };
    }
    else{
      user = {
        fullname: "Development User",
        cwid: "AAAAA",
        lastname : "User",
        firstname : "Developer",
        email: "DeveloperDummy@bayer.com",
        roles: ['SSTUser','bulkUploadUser','XPWDUser'], //'SSTUser','bulkUploadUser','XPWDUser' // to be populated from token details
      };
    }
    this.currentUserSubject.next(user);
  }

  logout(): void {
    this.currentUserSubject.next(null);
  }

  public get currentUserValue(): User | null {
    return this.currentUserSubject.value;
  }

  public isAuthorized(allowedRoles: string[]): boolean {
    const user = this.currentUserValue;
    if (!user) return false;
    return user.roles.some(role => allowedRoles.includes(role));
  }
}
