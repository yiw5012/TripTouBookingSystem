import { ComponentFixture, TestBed } from '@angular/core/testing';

import { AddGuide } from './addguide';

describe('Addguide', () => {
  let component: AddGuide;
  let fixture: ComponentFixture<AddGuide>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [AddGuide]
    })
    .compileComponents();

    fixture = TestBed.createComponent(AddGuide);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
