import { ComponentFixture, TestBed } from '@angular/core/testing';
import { ReactiveFormsModule, FormBuilder, FormGroup, FormControl,FormGroupDirective } from '@angular/forms';
import { StatusComponent } from './status.component';

describe('StatusComponent', () => {
  let component: StatusComponent;
  let fixture: ComponentFixture<StatusComponent>;
  let formGroupDirective: jasmine.SpyObj<FormGroupDirective>;

  beforeEach(async () => {
    formGroupDirective = jasmine.createSpyObj('FormGroupDirective', ['form']);
    
    await TestBed.configureTestingModule({
      imports: [ReactiveFormsModule,StatusComponent],
      providers: [
        { provide: FormGroupDirective, useValue: formGroupDirective },
        FormBuilder
      ]
    }).compileComponents();

    fixture = TestBed.createComponent(StatusComponent);
    component = fixture.componentInstance;
    // Initialize the form group in the spy
    component.childForm = component.parentForm.form;
    formGroupDirective.form = new FormGroup({
      statusData: new FormGroup({
        employeeEndDate: new FormControl(null),
        employeeStartDate: new FormControl(null),
      })
    });
    // fixture.detectChanges();
    component.childForm = component.parentForm.form;

    // Call detectChanges to trigger ngOnInit
    fixture.detectChanges();
  });

  it('should create the component', () => {
    expect(component).toBeTruthy();
  });

  it('should set status to true when both dates are empty', () => {
    component.childForm = component.parentForm.form;
    component.childForm?.patchValue({statusData:{
      employeeStartDate: null,
      employeeEndDate: null
    }});

    component.getStaus();
    expect(component.status).toBeTrue();
  });

  it('should set status to false when end date is in the past', () => {
    const pastDate = new Date(Date.now() - 10000).toISOString(); // 10 seconds in the past
    component.childForm = component.parentForm.form;
    component.childForm?.patchValue({statusData:{
      employeeStartDate: null,
      employeeEndDate: pastDate
    }});

    component.getStaus();
    expect(component.status).toBeFalse();
  });

  it('should set status to true when start date is in the past', () => {
    const pastDate = new Date(Date.now() - 10000).toISOString(); // 10 seconds in the past
    component.childForm = component.parentForm.form;
    component.childForm?.patchValue({statusData:{
      employeeStartDate: pastDate,
      employeeEndDate: null
    }});

    component.getStaus();
    expect(component.status).toBeTrue();
  });

  it('should set status to true when start date is before end date', () => {
    const startDate = new Date(Date.now() - 10000).toISOString(); // 10 seconds in the past
    const endDate = new Date(Date.now() + 10000).toISOString(); // 10 seconds in the future
    component.childForm = component.parentForm.form;
    component.childForm?.patchValue({statusData:{
      employeeStartDate: startDate,
      employeeEndDate: endDate
    }});

    component.getStaus();
    expect(component.status).toBeTrue();
  });

  it('should set status to false when start date is after end date', () => {
    const startDate = new Date(Date.now() + 10000).toISOString(); // 10 seconds in the future
    const endDate = new Date(Date.now()).toISOString(); // now
    component.childForm = component.parentForm.form;
    component.childForm?.patchValue({statusData:{
      employeeStartDate: startDate,
      employeeEndDate: endDate
    }});

    component.getStaus();
    expect(component.status).toBeFalse();
  });

  it('should update status when employeeStartDate changes', () => {
    const startDate = new Date(Date.now() - 10000).toISOString(); // 10 seconds in the past
    const endDate = new Date(Date.now() + 10000).toISOString(); // 10 seconds in the future
    component.childForm = component.parentForm.form;
    component.childForm?.patchValue({statusData:{
      employeeStartDate: startDate,
      employeeEndDate: endDate
    }});

    component.getStaus();
    expect(component.status).toBeTrue();
  });

  it('should update status when employeeEndDate changes', () => {
    const startDate = new Date(Date.now() - 10000).toISOString(); // 10 seconds in the past
    const endDate = new Date(Date.now() + 10000).toISOString(); // 10 seconds in the future
    component.childForm = component.parentForm.form;
    component.childForm?.patchValue({statusData:{
      employeeStartDate: startDate,
      employeeEndDate: endDate
    }});

    component.getStaus();
    expect(component.status).toBeTrue();

    // Change end date to a past date
    const pastEndDate = new Date(Date.now() - 20000).toISOString(); // 20 seconds in the past
    component.childForm.get('statusData')?.patchValue({
      employeeEndDate: pastEndDate
    });

    component.getStaus();
    expect(component.status).toBeFalse();
  });
});