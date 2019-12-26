import 'dart:typed_data';

import 'package:bloom_filter/bloom_filter.dart';
import 'package:bloom_filter_builder/src/builder.dart';
import 'package:flutter_test/flutter_test.dart';

const _data = ['foo', 'bar'];

void main() {
  test('generate source', () {
    const builder = BloomFilterGenerator();
    final filter = builder.newBloomFilter(_data);
    expect(filter.containsAll(_data), true);
    final buf = StringBuffer();
    builder.serializeFilter(filter, 'test', buf);
    expect(
        buf.toString(),
        'BloomFilter testBloomFilter = '
        'BloomFilter.withSizeAndBitVector(12, 2, Uint32List.fromList([2421, ]).buffer);');
  });

  test('(de)serialization', () {
    final filter = const BloomFilterGenerator().newBloomFilter(_data);
    expect(filter.containsAll(_data), true);
    final bits = filter.bitVectorListForStorage();
    final items = filter.length;
    final size = bits.length;
    final newFilter = BloomFilter.withSizeAndBitVector(
        size, items, Uint32List.fromList(bits).buffer);
    expect(newFilter.containsAll(_data), true);
  });

  test('valid identifier', () {
    const builder = BloomFilterGenerator();
    final filter = builder.newBloomFilter(_data);
    expect(filter.containsAll(_data), true);
    final buf = StringBuffer();
    builder.serializeFilter(filter, 'test2.0', buf);
    expect(
        buf.toString(),
        'BloomFilter test2_0BloomFilter = '
        'BloomFilter.withSizeAndBitVector(12, 2, Uint32List.fromList([2421, ]).buffer);');
  });

  test('lower camel case', () {
    const builder = BloomFilterGenerator();
    final filter = builder.newBloomFilter(_data);
    expect(filter.containsAll(_data), true);
    final buf = StringBuffer();
    builder.serializeFilter(filter, 'test2.0-foo-bar', buf);
    expect(
        buf.toString(),
        'BloomFilter test2_0FooBarBloomFilter = '
        'BloomFilter.withSizeAndBitVector(12, 2, Uint32List.fromList([2421, ]).buffer);');
  });
}
