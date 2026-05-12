import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../models/vision_record.dart';

final historyBoxProvider = Provider<Box<VisionRecord>>((ref) {
  return Hive.box<VisionRecord>('vision_records');
});

final historyRecordsProvider = StreamProvider<List<VisionRecord>>((ref) async* {
  final box = ref.watch(historyBoxProvider);
  List<VisionRecord> snapshot() {
    final list = box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  yield snapshot();
  await for (final _ in box.watch()) {
    yield snapshot();
  }
});

final recordByIdProvider =
    Provider.family<VisionRecord?, String>((ref, id) {
  final box = ref.watch(historyBoxProvider);
  return box.get(id);
});
