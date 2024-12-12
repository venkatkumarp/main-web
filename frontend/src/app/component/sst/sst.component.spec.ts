import { ComponentFixture, TestBed } from '@angular/core/testing';
import { ReactiveFormsModule } from '@angular/forms';
import { SstComponent } from './sst.component'; // Adjust the import path as necessary
import { PermissionService } from '../../services/permission.service';
import { APIService } from '../../services/api.service';
import { of } from 'rxjs';

describe('SstComponent', () => {
  let component: SstComponent;
  let fixture: ComponentFixture<SstComponent>;
  let apiService: jasmine.SpyObj<APIService>;
  let permissionService: jasmine.SpyObj<PermissionService>;

  beforeEach(async () => {
    const apiServiceSpy = jasmine.createSpyObj('APIService', ['searchByEmail', 'getUserData']);
    const permissionServiceSpy = jasmine.createSpyObj('PermissionService', ['canAccess']);

    await TestBed.configureTestingModule({
      imports: [ReactiveFormsModule,SstComponent],
      declarations: [],
      providers: [
        { provide: APIService, useValue: apiServiceSpy },
        { provide: PermissionService, useValue: permissionServiceSpy }
      ]
    }).compileComponents();

    fixture = TestBed.createComponent(SstComponent);
    component = fixture.componentInstance;
    apiService = TestBed.inject(APIService) as jasmine.SpyObj<APIService>;
    permissionService = TestBed.inject(PermissionService) as jasmine.SpyObj<PermissionService>;
  });

  it('should create the component', () => {
    expect(component).toBeTruthy();
  });

  it('should call searchByEmail and update filteredAccount on autoCompleteSearch', () => {
    const mockResponse = [{ fullName: 'Test User', email: 'test.user@bayer.com' }];
    apiService.searchByEmail.and.returnValue(of(mockResponse));

    component.autoCompleteSearch({ query: 'test' });

    expect(apiService.searchByEmail).toHaveBeenCalledWith('test');
    expect(component.filteredAccount).toEqual(mockResponse);
  });

  it('should load user details and update form on loadUserDetails', () => {
    const mockUserData = [{
      "title": "USER.TEST@BAYER.COM",
      "emailAddress": "user.test@bayer.com",
      "cwid": "ABCDE",
      "company": "Cognizant",
      "hoursWeek": 40,
      "roles": [
          "GDSA Clinical Data Reviewer"
      ],
      "country": "Usa",
      "legalEntity": "BHCP Inc/USA",
      "topFunction": "PH Research&Dev.",
      "subFunction": "CDPE",
      "subSubFunction": "CDPE-DMOI",
      "backupId": null,
      "timekeepingAssistantId": "user.test1@bayer.com",
      "timekeepingAssistant2Id": null,
      "employeeStartDate": "2022-03-01",
      "employeeEndDate": null,
      "selfApprover": "no",
      "fullName": "User, Test",
      "supervisorId": "user.test@bayer.com",
      "costCenter": "G353/E413267412",
      "function": "CD&O",
      "externalFlag": "yes",
      "isExistingUser": true
  }];
    apiService.getUserData.and.returnValue(of(mockUserData));

    component.loadUserDetails({ value: { email: 'test.user@bayer.com' } });

    expect(apiService.getUserData).toHaveBeenCalledWith('test.user@bayer.com');
    expect(component.heading).toEqual('User, Test');
    expect(component.sstFormGroup.get('personalDataFormGroup')?.value.cwid).toEqual(mockUserData[0].cwid);
    expect(component.detailsLoaded).toBeTrue();
    expect(component.isLoading).toBeFalse();
  });

  it('should reset form and heading on cancel', () => {
    component.cancel();

    expect(component.detailsLoaded).toBeFalse();
    expect(component.heading).toEqual(component.headingDefault);
  });

  it('should submit form when valid', () => {
    spyOn(console, 'log'); // Spy on console.log to check if it gets called
    component.sstFormGroup.patchValue({
      personalDataFormGroup: { name: 'Test User', emailAddress: 'test.user@bayer.com' }
    });

    component.onSubmit();

    expect(console.log).toHaveBeenCalledWith(component.sstFormGroup.value);
  });

  it('should retrun Initials of FullNmae', () => {
    const initials = component.getInitials('Test, User')
    expect(initials).toEqual('TU');
  });
  
  it('should retrun permission service', () => {
    const permission = component.accessPermission
    expect(permission).toEqual(permissionService);
  });
});
