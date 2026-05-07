import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:lazychef/main.dart';

void main() {
  testWidgets('shows the login experience by default', (tester) async {
    await tester.pumpWidget(const LazyChefApp());

    expect(find.text('LazyChef'), findsNothing);
    expect(find.text('Your fridge, organized for dinner.'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);
  });

  testWidgets('home quick access grid fits on compact phones', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const LazyChefApp());
    await tester.ensureVisible(find.text('Sign in'));
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Fast scan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
