import 'package:bloom_filter/bloom_filter.dart';
import 'package:bloom_filter_builder/src/builder.dart';
import 'package:flutter_test/flutter_test.dart';

const _data = ['foo', 'bar'];

void main() {
  test('generate source', () {
    final builder = BloomFilterBuilder();
    final filter = builder.makeBloomFilter(_data);
    expect(filter.containsAll(_data), true);
    final buf = StringBuffer();
    builder.generateSource(filter, 'test', buf);
    expect(
        buf.toString(),
        'BloomFilter testBloomFilter = '
        'BloomFilter.withSize(12, 2, [true, false, true, false, true, true, true, false, true, false, false, true, ]);');
  });

  test('deserialization', () {
    final builder = BloomFilterBuilder();
    final filter = builder.makeBloomFilter(_data);
    expect(filter.containsAll(_data), true);
    final bits = filter.getBits();
    final items = filter.length;
    final size = bits.length;
    final newFilter = BloomFilter.withSize(size, items)..setBits(bits);
    expect(newFilter.containsAll(_data), true);
  });
}
