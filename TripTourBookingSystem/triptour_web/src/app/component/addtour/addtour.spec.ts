import { ComponentFixture, TestBed } from '@angular/core/testing';

import { Addtour } from './addtour';

describe('Addtour', () => {
  let component: Addtour;
  let fixture: ComponentFixture<Addtour>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [Addtour]
    })
    .compileComponents();

    fixture = TestBed.createComponent(Addtour);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
