#!/usr/bin/env dart
import 'dart:io';

import 'package:args/args.dart';
import 'package:bloom_filter_builder/src/builder.dart';
import 'package:path/path.dart' as p;

void main(List<String> args) {
  final parser = ArgParser()
    ..addOption('probability',
        abbr: 'p',
        help:
            'The probability of false positives (default: $kDefaultProbability)')
    ..addOption('output', abbr: 'o', help: "Output path ('-' for stdout)");
  final results = parser.parse(args);

  if (results.rest.isEmpty) {
    print('usage: generate_bloom_filter [options] <files>...');
    print(parser.usage);
    exit(1);
  }

  var probability = kDefaultProbability;
  if (results['probability'] != null) {
    probability = double.parse(results['probability'].toString());
  }

  for (final arg in results.rest) {
    final file = File(arg);
    final source = generateOne(file, probability);
    final outPath = results['output']?.toString() ??
        p.setExtension(file.path, kOutputExtension);
    if (outPath == '-') {
      print(source);
    } else {
      File(outPath).writeAsStringSync(source);
    }
  }
}

String generateOne(File file, double probability) {
  final lines = file.readAsLinesSync();
  final name = p.basenameWithoutExtension(file.path);
  return const BloomFilterGenerator().generate(lines, probability, name);
}
