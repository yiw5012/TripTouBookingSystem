import { ComponentFixture, TestBed } from '@angular/core/testing';

import { BookingApproval } from './booking-approval';

describe('BookingApproval', () => {
  let component: BookingApproval;
  let fixture: ComponentFixture<BookingApproval>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [BookingApproval]
    })
    .compileComponents();

    fixture = TestBed.createComponent(BookingApproval);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
