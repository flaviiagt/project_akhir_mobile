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
}
