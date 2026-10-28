import 'package:flutter_test/flutter_test.dart';
import 'package:studytrip/data/models.dart';
import 'package:studytrip/services/notification_service.dart';

ChecklistItem _item(int id, DateTime deadline, {bool done = false}) => ChecklistItem(
      id: id,
      title: 'Tugas $id',
      category: 'Dokumen',
      deadline: deadline,
      done: done,
    );

void main() {
  test('deadline hari ini, sebelum jam 09.00: pengingat 09.00 dan 17.00', () {
    final now = DateTime(2026, 10, 28, 7, 0);
    final plan = NotificationService.plan([_item(1, DateTime(2026, 10, 28))], now);
    expect(plan.map((e) => e.id).toSet(), {10, 15});
    expect(plan.any((e) => e.catchUp), isFalse);
  });

  test('deadline hari ini, sudah lewat 09.00: ada pengingat susulan + sore', () {
    final now = DateTime(2026, 10, 28, 13, 0);
    final plan = NotificationService.plan([_item(1, DateTime(2026, 10, 28))], now);
    final catchUp = plan.singleWhere((e) => e.catchUp);
    expect(catchUp.id, 16);
    expect(catchUp.when.isAfter(now), isTrue);
    expect(plan.any((e) => e.id == 15), isTrue);
  });

  test('deadline hari ini, sudah lewat 17.00: hanya pengingat susulan', () {
    final now = DateTime(2026, 10, 28, 20, 0);
    final plan = NotificationService.plan([_item(1, DateTime(2026, 10, 28))], now);
    expect(plan.map((e) => e.id).toList(), [16]);
  });

  test('tugas selesai atau tanpa deadline tidak diingatkan', () {
    final now = DateTime(2026, 10, 28, 7, 0);
    final plan = NotificationService.plan([
      _item(1, DateTime(2026, 10, 28), done: true),
      const ChecklistItem(id: 2, title: 'Tanpa deadline', category: 'Lainnya'),
    ], now);
    expect(plan, isEmpty);
  });

  test('deadline 5 hari lagi: hanya pengingat H-3, H-1, hari-H', () {
    final now = DateTime(2026, 10, 28, 7, 0);
    final plan = NotificationService.plan([_item(3, DateTime(2026, 11, 2))], now);
    expect(plan.map((e) => e.id).toSet(), {33, 31, 30});
    expect(plan.every((e) => e.when.hour == 9), isTrue);
  });
}
