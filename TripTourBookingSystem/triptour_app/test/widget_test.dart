// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:triptour_app/page/auth/registerPage.dart';

void main() {
  test('duplicate email error maps to a clear warning message', () {
    final error = FirebaseAuthException(
      code: 'email-already-in-use',
      message: 'The email address is already in use by another account.',
    );

    expect(formatRegistrationError(error), 'อีเมลนี้ถูกใช้งานแล้ว');
  });
}
