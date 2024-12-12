import { ComponentFixture, TestBed } from '@angular/core/testing';

import { LineManagementComponent } from './line-management.component';
import { FormBuilder, FormGroupDirective } from '@angular/forms';
import { APIService } from '../../../services/api.service';
import { of } from 'rxjs';

describe('LineManagementComponent', () => {
  let component: LineManagementComponent;
  let fixture: ComponentFixture<LineManagementComponent>;
  let mockFormGroupDirective: FormGroupDirective;
  let apiService: jasmine.SpyObj<APIService>;
  beforeEach(async () => {
    const fb = new FormBuilder();
    const apiServiceSpy = jasmine.createSpyObj('APIService', ['searchByEmail']);
    mockFormGroupDirective = new FormGroupDirective([], []);
    mockFormGroupDirective.form = fb.group({
      test: fb.control(null)
    });

    await TestBed.configureTestingModule({
      imports: [LineManagementComponent],
      providers:[{ provide: FormGroupDirective, useValue: mockFormGroupDirective },{ provide: APIService, useValue: apiServiceSpy }]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(LineManagementComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
    apiService = TestBed.inject(APIService) as jasmine.SpyObj<APIService>;
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
  it('should retrun Initials of FullNmae', () => {
    const initials = component.getInitials('Test, User')
    expect(initials).toEqual('TU');
  });

  it('should call searchByEmail and update Suggestion on autoCompleteSearch', () => {
    const mockResponse = [{ fullName: 'Test User', email: 'test.user@bayer.com' }];
    apiService.searchByEmail.and.returnValue(of(mockResponse));

    component.autoCompleteSearch({ query: 'test' },'');
    expect(apiService.searchByEmail).toHaveBeenCalledWith('test');
    expect(component.timeAssist2Suggestion).toEqual([]);
    
    component.autoCompleteSearch({ query: 'test' },'supervisorId');
    expect(apiService.searchByEmail).toHaveBeenCalledWith('test');
    expect(component.supervisorSuggestion).toEqual(mockResponse);

    component.autoCompleteSearch({ query: 'test' },'backupId');
    expect(apiService.searchByEmail).toHaveBeenCalledWith('test');
    expect(component.backupSuggestion).toEqual(mockResponse);

    component.autoCompleteSearch({ query: 'test' },'timekeepingAssistantId');
    expect(apiService.searchByEmail).toHaveBeenCalledWith('test');
    expect(component.timeAssistSuggestion).toEqual(mockResponse);

    component.autoCompleteSearch({ query: 'test' },'timekeepingAssistant2Id');
    expect(apiService.searchByEmail).toHaveBeenCalledWith('test');
    expect(component.timeAssist2Suggestion).toEqual(mockResponse);
    
  });
});
