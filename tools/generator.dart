import 'dart:async';

import 'package:build_runner/build_runner.dart';
import 'package:built_value_generator/built_value_generator.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_gen/src/builder.dart';
import 'package:source_gen/src/generator.dart';

Future<Null> main(List<String> args) async {
  await watch(<BuildAction>[
    new BuildAction(
        new PartBuilder(<Generator>[
          const BuiltValueGenerator(),
        ]),
        'socket_io_client',
        inputs: const <String>['lib/src/models/**.dart'])
  ], deleteFilesByDefault: true);
}
