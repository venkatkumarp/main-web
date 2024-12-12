import { TestBed } from '@angular/core/testing';

import { PermissionService } from './permission.service';
import { AuthService } from './auth.service';

describe('PermissionService', () => {
  let service: PermissionService;
  let authService: AuthService;
  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(PermissionService);
    authService = TestBed.inject(AuthService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
  
  it('should return true if task can Access', () => {
    authService.login()
    const access = service.canAccess(service.taskList.read.sst)
    expect(access).toBeTrue();
  });

  it('should return false if user not logged in', () => {
    const access = service.canAccess(service.taskList.read.sst)
    expect(access).toBeFalse();
  });
});
