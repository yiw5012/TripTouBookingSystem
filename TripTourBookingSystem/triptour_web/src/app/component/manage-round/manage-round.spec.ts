import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ManageRound } from './manage-round';

describe('ManageRound', () => {
  let component: ManageRound;
  let fixture: ComponentFixture<ManageRound>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [ManageRound]
    })
    .compileComponents();

    fixture = TestBed.createComponent(ManageRound);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
