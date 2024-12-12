import { TestBed } from '@angular/core/testing';
import { AuthService, User } from './auth.service'; 

describe('AuthService', () => {
  let service: AuthService;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [AuthService]
    });
    service = TestBed.inject(AuthService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  describe('login', () => {
    it('should set current user when access token is provided', () => {
      //This is Dummy Token for testing perpose
      const accessToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiVGVzdCBVc2VyIiwiaHR0cHM6Ly9iYXllci5jb20vY3dpZCI6IjEyMzQ1IiwiZ2l2ZW5fbmFtZSI6IlRlc3QiLCJmYW1pbHlfbmFtZSI6IlVzZXIiLCJ1bmlxdWVfbmFtZSI6InRlc3QudXNlckBiYXllci5jb20iLCJpYXQiOjE2MjAxNDIwMDB9.SDfIGdgAxqPkqwpB2eL1gywRcYQe9Lyb98dqrn-oRtE'; 
      const idToken = 'mockIdToken';
      const refreshToken = 'mockRefreshToken';

      service.login(accessToken, idToken, refreshToken);

      service.currentUser.subscribe(user => {
        console.log(user);
        expect(user).toBeTruthy();
        expect(user?.fullname).toEqual('Test User');
        expect(user?.cwid).toEqual('12345');
        expect(user?.firstname).toEqual('Test');
        expect(user?.lastname).toEqual('User');
        expect(user?.email).toEqual('test.user@bayer.com');
        expect(user?.roles).toEqual(['SSTUser', 'bulkUploadUser', 'XPWDUser']);
      });
    });

    it('should set a default user when no access token is provided', () => {
      service.login();

      service.currentUser.subscribe(user => {
        expect(user).toBeTruthy();
        expect(user?.fullname).toEqual('Development User');
        expect(user?.cwid).toEqual('AAAAA');
        expect(user?.firstname).toEqual('Developer');
        expect(user?.lastname).toEqual('User');
        expect(user?.email).toEqual('DeveloperDummy@bayer.com');
        expect(user?.roles).toEqual(['SSTUser', 'bulkUploadUser', 'XPWDUser']);
      });
    });
  });

  describe('logout', () => {
    it('should clear the current user', () => {
      service.logout();

      service.currentUser.subscribe(user => {
        expect(user).toBeNull();
      });
    });
  });

  describe('isAuthorized', () => {
    it('should return true if user has at least one allowed role', () => {
      service.login();
      const user: User = {
        fullname: 'Test User',
        cwid: '12345',
        firstname: 'Test',
        lastname: 'User',
        email: 'test.user@bayer.com',
        roles: ['SSTUser', 'bulkUploadUser']
      };
      service['currentUserSubject'].next(user);

      const isAuthorized = service.isAuthorized(['bulkUploadUser']);
      expect(isAuthorized).toBeTrue();
    });

    it('should return false if user has no allowed roles', () => {
      const user: User = {
        fullname: 'Test User',
        cwid: '12345',
        firstname: 'Test',
        lastname: 'User',
        email: 'test.user@bayer.com',
        roles: ['SSTUser']
      };
      service['currentUserSubject'].next(user);

      const isAuthorized = service.isAuthorized(['Admin']);
      expect(isAuthorized).toBeFalse();
    });

    it('should return false if user is null', () => {
      service.logout(); // Ensure user is logged out

      const isAuthorized = service.isAuthorized(['bulkUploadUser']);
      expect(isAuthorized).toBeFalse();
    });
  });

  describe('currentUserValue', () => {
    it('should return the current user value', () => {
      const user: User = {
        fullname: 'Test User',
        cwid: '12345',
        firstname: 'Test',
        lastname: 'User',
        email: 'test.user@bayer.com',
        roles: ['SSTUser']
      };
      service['currentUserSubject'].next(user);

      expect(service.currentUserValue).toEqual(user);
    });

    it('should return null if no user is set', () => {
      service.logout(); // Ensure user is logged out
      expect(service.currentUserValue).toBeNull();
    });
  });
});
