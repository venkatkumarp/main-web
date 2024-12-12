import { ComponentFixture, TestBed } from '@angular/core/testing';

import { BusinessUnitComponent } from './business-unit.component';
import { FormBuilder, FormGroupDirective } from '@angular/forms';
import { APIService } from '../../../services/api.service';
import { of } from 'rxjs';

describe('BusinessUnitComponent', () => {
  let component: BusinessUnitComponent;
  let fixture: ComponentFixture<BusinessUnitComponent>;
  let mockFormGroupDirective: FormGroupDirective;
  let apiService: jasmine.SpyObj<APIService>;

  beforeEach(async () => {
    const fb = new FormBuilder();
    mockFormGroupDirective = new FormGroupDirective([], []);
    mockFormGroupDirective.form = fb.group({
      test: fb.control(null)
    });
    const apiServiceSpy = jasmine.createSpyObj('APIService', ['getCostCenter','getSubSubFunction']);
    

    await TestBed.configureTestingModule({
      imports: [BusinessUnitComponent],
      providers:[{ provide: FormGroupDirective, useValue: mockFormGroupDirective },{ provide: APIService, useValue: apiServiceSpy }]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(BusinessUnitComponent);
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
  
  it('should call getCostCenter and get cost center list', () => {
    const mock = [
      {
          "costCenter": "G353/E413267412",
          "legalEntity": "BHCP Inc/USA",
          "function": "CD&O",
          "subFunction": "CDPE",
          "topFunction": "PH Research&Dev.",
          "country": "Usa"
      },{
          "costCenter": "G353/E413267412",
          "legalEntity": "BHCP Inc/USA",
          "function": "CD&O",
          "subFunction": "CDPE",
          "topFunction": "PH Research&Dev.",
          "country": "Usa"
      }
  ]
    apiService.getCostCenter.and.returnValue(of(mock))
    component.costCenterSearch({query: "test"})

    expect(apiService.getCostCenter).toHaveBeenCalledWith("test");
    expect(component.costCenterSuggestion).toEqual(mock)
  });

  it('should select cost center',() => {
    const mock = {
      "costCenter": "G353/E413267412",
      "legalEntity": "BHCP Inc/USA",
      "function": "CD&O",
      "subFunction": "CDPE",
      "topFunction": "PH Research&Dev.",
      "country": "Usa"
  }
    component.costCenterSelected({value: mock});
    expect(component.ccSelected).toEqual(mock.costCenter);
  });

  it('should search sub sub function and return list of sub sub function', ()=>{
    const mock = [
      "CDPE",
      "CDPE-SPA",
      "CDPE-DMOI",
      "CDPE-CDM",
      "CDPE-CDP",
      "CSA"
  ]

    apiService.getSubSubFunction.and.returnValue(of(mock))
    component.ccSelected = {costcenter: "test"}
    component.searchsubsubFn({query: "test"})

    expect(apiService.getSubSubFunction).toHaveBeenCalledWith(component.ccSelected);
    expect(component.subsubFnSuggestion).toEqual(mock);
  });
});
