import { TestBed } from '@angular/core/testing';

import { authInterceptor } from './auth.interceptor';

describe('AuthInterceptor', () => {
  beforeEach(() => TestBed.configureTestingModule({
    providers: [
      authInterceptor
      ]
  }));

  it('should be created', () => {
    const interceptor: authInterceptor = TestBed.inject(authInterceptor);
    expect(interceptor).toBeTruthy();
  });
});