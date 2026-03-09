import { ComponentFixture, TestBed } from '@angular/core/testing';

import { Addguide } from './addguide';

describe('Addguide', () => {
  let component: Addguide;
  let fixture: ComponentFixture<Addguide>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [Addguide]
    })
    .compileComponents();

    fixture = TestBed.createComponent(Addguide);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
