import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ManageTour } from './manage-tour';

describe('ManageTour', () => {
  let component: ManageTour;
  let fixture: ComponentFixture<ManageTour>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [ManageTour]
    })
    .compileComponents();

    fixture = TestBed.createComponent(ManageTour);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
