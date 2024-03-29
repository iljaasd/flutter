// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/commands/validate_project.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/project_validator.dart';
import 'package:flutter_tools/src/project_validator_result.dart';

import '../../src/context.dart';
import '../../src/test_flutter_command_runner.dart';

class ProjectValidatorDummy extends ProjectValidator {
  @override
  Future<List<ProjectValidatorResult>> start(FlutterProject project) async{
    return <ProjectValidatorResult>[
      const ProjectValidatorResult(name: 'pass', value: 'value', status: StatusProjectValidator.success),
      const ProjectValidatorResult(name: 'fail', value: 'my error', status: StatusProjectValidator.error),
      const ProjectValidatorResult(name: 'pass two', value: 'pass', warning: 'my warning', status: StatusProjectValidator.warning),
    ];
  }

  @override
  bool supportsProject(FlutterProject project) {
    return true;
  }

  @override
  String get title => 'First Dummy';
}

class ProjectValidatorSecondDummy extends ProjectValidator {
  @override
  Future<List<ProjectValidatorResult>> start(FlutterProject project) async{
    return <ProjectValidatorResult>[
      const ProjectValidatorResult(name: 'second', value: 'pass', status: StatusProjectValidator.success),
      const ProjectValidatorResult(name: 'other fail', value: 'second fail', status: StatusProjectValidator.error),
    ];
  }

  @override
  bool supportsProject(FlutterProject project) {
    return true;
  }

  @override
  String get title => 'Second Dummy';
}

class ProjectValidatorCrash extends ProjectValidator {
  @override
  Future<List<ProjectValidatorResult>> start(FlutterProject project) async{
    throw Exception('my exception');
  }

  @override
  bool supportsProject(FlutterProject project) {
    return true;
  }

  @override
  String get title => 'Crash';
}

void main() {
  FileSystem fileSystem;

  group('analyze project command', () {

    setUp(() {
      fileSystem = MemoryFileSystem.test();
    });

    testUsingContext('success, error and warning', () async {
      final BufferLogger loggerTest = BufferLogger.test();
      final ValidateProjectCommand command = ValidateProjectCommand(
          fileSystem: fileSystem,
          logger: loggerTest,
          allProjectValidators: <ProjectValidator>[
            ProjectValidatorDummy(),
            ProjectValidatorSecondDummy()
          ]
      );
      final CommandRunner<void> runner = createTestCommandRunner(command);

      await runner.run(<String>['validate-project']);

      const String expected = '\n'
          '┌──────────────────────────────────────────┐\n'
          '│ First Dummy                              │\n'
          '│ [✓] pass: value                          │\n'
          '│ [✗] fail: my error                       │\n'
          '│ [!] pass two: pass (warning: my warning) │\n'
          '│ Second Dummy                             │\n'
          '│ [✓] second: pass                         │\n'
          '│ [✗] other fail: second fail              │\n'
          '└──────────────────────────────────────────┘\n';

      expect(loggerTest.statusText, contains(expected));
    });

    testUsingContext('crash', () async {
      final BufferLogger loggerTest = BufferLogger.test();
      final ValidateProjectCommand command = ValidateProjectCommand(
          fileSystem: fileSystem,
          logger: loggerTest,
          allProjectValidators: <ProjectValidator>[ProjectValidatorCrash()]
      );
      final CommandRunner<void> runner = createTestCommandRunner(command);

      await runner.run(<String>['validate-project']);

      const String expected = '[☠] Exception: my exception: #0      ProjectValidatorCrash.start';

      expect(loggerTest.statusText, contains(expected));
    });
  });
}
