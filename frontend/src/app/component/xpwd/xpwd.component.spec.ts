import { ComponentFixture, TestBed } from '@angular/core/testing';

import { XpwdComponent } from './xpwd.component';

describe('XpwdComponent', () => {
  let component: XpwdComponent;
  let fixture: ComponentFixture<XpwdComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [XpwdComponent]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(XpwdComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
