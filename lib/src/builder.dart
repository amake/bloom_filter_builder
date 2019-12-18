import 'dart:async';
import 'dart:io';

import 'package:bloom_filter/bloom_filter.dart';
import 'package:build/build.dart';
import 'package:build/build.dart' show log;
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as p;

const kDefaultProbability = 0.1;
const kOutputExtension = '.g.dart';
final _kInvalidIdentifierPattern = RegExp(r'[^a-zA-Z0-9$]');

class BloomFilterBuilder implements Builder {
  const BloomFilterBuilder([this._options = BuilderOptions.empty])
      : assert(_options != null);

  final BuilderOptions _options;

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    log?.fine('Processing ${buildStep.inputId.path}\n');
    log?.fine('Config: ${_options.config}\n');

    final inFile = File(buildStep.inputId.path);
    Iterable items;
    try {
      items = inFile.readAsLinesSync().where((line) => line.isNotEmpty);
    } on Exception catch (e) {
      log?.severe(e);
      items = [];
    }

    final name = p.basenameWithoutExtension(buildStep.inputId.path);
    final probability = _options.config['probability'] as double;
    final outString =
        const BloomFilterGenerator().generate(items, probability, name);

    final outFile = buildStep.inputId.changeExtension(kOutputExtension);
    await buildStep.writeAsString(outFile, outString);
  }

  @override
  Map<String, List<String>> get buildExtensions => const {
        '.txt': [kOutputExtension],
      };
}

class BloomFilterGenerator {
  const BloomFilterGenerator();

  String generate(Iterable items, double probability, String name) {
    final bloomFilter = newBloomFilter(items, probability);
    final buf = StringBuffer()..write(r'''import 'dart:typed_data';
import 'package:bloom_filter/bloom_filter.dart';

''');
    serializeFilter(bloomFilter, name, buf);

    final outString = buf.toString();
    try {
      return DartFormatter().format(outString).toString();
    } on Exception catch (e) {
      log?.warning(e);
      return outString;
    }
  }

  BloomFilter<T> newBloomFilter<T>(Iterable<T> items, [double probability]) =>
      BloomFilter<T>.withProbability(
          probability ?? kDefaultProbability, items.length)
        ..addAll(items);

  void serializeFilter(BloomFilter bloomFilter, String name, StringBuffer buf) {
    final bits = bloomFilter.bitVectorListForStorage();
    final items = bloomFilter.length;
    final size = bloomFilter.bitVectorSize;
    final filterName = '${name.toLowerCase()}BloomFilter'
        .replaceAll(_kInvalidIdentifierPattern, '_');
    buf.write(
        'BloomFilter $filterName = BloomFilter.withSizeAndBitVector($size, $items, Uint32List.fromList([');
    for (final bit in bits) {
      buf..write(bit.toString())..write(', ');
    }
    buf.write(']).buffer);');
  }
}
