import 'package:dio_scope/src/console/data/store/in_memory_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InMemoryStore', () {
    test('inserts newest-first', () {
      final store = InMemoryStore<int>(maxItems: 10);
      store
        ..add(1)
        ..add(2)
        ..add(3);
      expect(store.items, [3, 2, 1]);
    });

    test('evicts oldest beyond capacity', () {
      final store = InMemoryStore<int>(maxItems: 2);
      store
        ..add(1)
        ..add(2)
        ..add(3);
      expect(store.items, [3, 2]);
    });

    test('update mutates the first match', () {
      final store = InMemoryStore<int>()..add(1)..add(2);
      store.update((v) => v == 1, (_) => 99);
      expect(store.items, [2, 99]);
    });

    test('remove and clear', () {
      final store = InMemoryStore<int>()..add(1)..add(2)..add(3);
      store.remove((v) => v == 2);
      expect(store.items, [3, 1]);
      store.clear();
      expect(store.items, isEmpty);
    });

    test('stream emits on change', () {
      final store = InMemoryStore<int>();
      expectLater(
        store.stream,
        emitsInOrder([
          [1],
          [2, 1],
        ]),
      );
      store
        ..add(1)
        ..add(2);
    });
  });
}
