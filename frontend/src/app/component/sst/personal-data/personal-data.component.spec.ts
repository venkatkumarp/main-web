import { ComponentFixture, TestBed } from '@angular/core/testing';

import { PersonalDataComponent } from './personal-data.component';
import { FormBuilder, FormGroupDirective } from '@angular/forms';
import { APIService } from '../../../services/api.service';
import { of } from 'rxjs';

describe('PersonalDataComponent', () => {
  let component: PersonalDataComponent;
  let fixture: ComponentFixture<PersonalDataComponent>;
  let mockFormGroupDirective: FormGroupDirective;
  let apiService: jasmine.SpyObj<APIService>;

  beforeEach(async () => {
    const fb = new FormBuilder();
    const apiServiceSpy = jasmine.createSpyObj('APIService', ['getCompany','getRoles']);
    mockFormGroupDirective = new FormGroupDirective([], []);
    mockFormGroupDirective.form = fb.group({
      test: fb.control(null)
    });
    await TestBed.configureTestingModule({
      imports: [PersonalDataComponent],
      providers: [{ provide: FormGroupDirective, useValue: mockFormGroupDirective },{ provide: APIService, useValue: apiServiceSpy }]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(PersonalDataComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
    apiService = TestBed.inject(APIService) as jasmine.SpyObj<APIService>;
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should call SearchCompany and get Company List', () => {
    const mockResponse = ['Company 1', 'Company 2'];
    apiService.getCompany.and.returnValue(of(mockResponse));

    component.searchCompany({ query: 'Company' });

    expect(apiService.getCompany).toHaveBeenCalledWith();
    expect(component.companySuggestion).toEqual(mockResponse);
  });

  it('should call SearchRole and get role List', () => {
    const mockResponse = ['Role 1', 'Role 2'];
    apiService.getRoles.and.returnValue(of(mockResponse));

    component.searchRole({ query: '2' });

    expect(apiService.getRoles).toHaveBeenCalledWith('2');
    expect(component.roleSuggestion).toEqual(mockResponse);
  });
  
  it('should call roleSelected and push argument in role array', () => {
    component.roleSelected({value:'Role 1'});
    expect(component.Roles).toEqual(['Role 1']);
  });
});
