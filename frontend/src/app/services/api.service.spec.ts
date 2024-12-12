import { TestBed } from '@angular/core/testing';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { APIService } from './api.service'; // Adjust the import path as necessary

describe('APIService', () => {
  let service: APIService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [APIService]
    });
    service = TestBed.inject(APIService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  describe('searchByEmail', () => {
    it('should return mock user data', (done) => {
      service.searchByEmail('user.test@bayer.com').subscribe(users => {
        expect(users.length).toBe(3);
        expect(users[0].fullName).toBe('Test, User');
        expect(users[1].status).toBe('1');
        done();
      });
    });
  });

  describe('getUserData', () => {
    it('should return mock user data', (done) => {
      service.getUserData('user.test@bayer.com').subscribe(user => {
        expect(user.length).toBe(1);
        expect(user[0].fullName).toBe('User, Test');
        expect(user[0].emailAddress).toBe('user.test@bayer.com');
        done();
      });
    });
  });

  describe('getCompany', () => {
    it('should return a list of companies', (done) => {
      service.getCompany().subscribe(companies => {
        expect(companies.length).toBeGreaterThan(0);
        expect(companies).toContain('BAYER');
        done();
      });
    });
  });

  describe('getSubSubFunction', () => {
    it('should return a list of sub-sub-functions', (done) => {
      service.getSubSubFunction('G353/E413267412').subscribe(subFunctions => {
        expect(subFunctions.length).toBe(6);
        expect(subFunctions).toContain('CDPE');
        done();
      });
    });
  });

  describe('getCostCenter', () => {
    it('should return a list of cost centers', (done) => {
      service.getCostCenter('G353/E413267412').subscribe(costCenters => {
        expect(costCenters.length).toBe(2);
        expect(costCenters[0].costCenter).toBe('G353/E413267412');
        done();
      });
    });
  });

  describe('getRoles', () => {
    it('should return a list of roles', (done) => {
      service.getRoles('someQuery').subscribe(roles => {
        expect(roles.length).toBe(2);
        expect(roles).toContain('Role1');
        done();
      });
    });
  });
});
