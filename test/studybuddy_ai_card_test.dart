import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studytrip/widgets/studybuddy_ai_card.dart';

void main() {
  testWidgets('aksi kamera dan galeri tampil di dalam jendela StudyBuddy', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) {
            context = ctx;
            return const Scaffold();
          },
        ),
      ),
    );

    StudyBuddyFloating.show(context);
    StudyBuddyFloating.open();
    await tester.pumpAndSettle();

    expect(find.text('Ambil gambar'), findsOneWidget);
    expect(find.text('Pilih galeri'), findsOneWidget);

    StudyBuddyFloating.hide();
    await tester.pumpAndSettle();
  });

  testWidgets('kolom pertanyaan tetap di atas keyboard yang terbuka', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) {
            context = ctx;
            return const Scaffold();
          },
        ),
      ),
    );

    StudyBuddyFloating.show(context);
    StudyBuddyFloating.open();
    await tester.pumpAndSettle();

    final input = tester.getRect(find.byType(TextField));
    expect(input.bottom, lessThanOrEqualTo(500));

    StudyBuddyFloating.hide();
    await tester.pumpAndSettle();
  });
}
