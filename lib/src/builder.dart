import 'dart:async';
import 'dart:io';

import 'package:bloom_filter/bloom_filter.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as p;

class BloomFilterBuilder implements Builder {
  const BloomFilterBuilder();

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final inFile = File(buildStep.inputId.path);
    List items;
    try {
      items = await inFile.readAsLines();
    } catch (e) {
      items = [];
    }

    final bloomFilter = makeBloomFilter(items);
    final buf = StringBuffer()
      ..write(r'''import 'package:bloom_filter/bloom_filter.dart';

''');
    final name = p.basenameWithoutExtension(buildStep.inputId.path);
    generateSource(bloomFilter, name, buf);

    String outString;
    try {
      outString = DartFormatter().format(buf.toString()).toString();
    } catch (err) {
      outString = '';
    }
    final outFile = buildStep.inputId.changeExtension('.dart');
    await buildStep.writeAsString(outFile, outString);
  }

  BloomFilter<T> makeBloomFilter<T>(List<T> items) =>
      BloomFilter<T>.withProbability(0.1, items.length)..addAll(items);

  void generateSource(BloomFilter bloomFilter, String name, StringBuffer buf) {
    final bits = bloomFilter.getBits();
    final items = bloomFilter.length;
    final size = bits.length;
    final filterName = name.toLowerCase() + 'BloomFilter';
    buf.write(
        'BloomFilter $filterName = BloomFilter.withSize($size, $items, [');
    for (final bit in bits) {
      buf..write(bit.toString())..write(', ');
    }
    buf.write(']);');
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        '.bloom.txt': ['.dart'],
      };
}
