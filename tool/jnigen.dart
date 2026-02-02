import 'dart:io';

import 'package:jnigen/jnigen.dart';

void main(List<String> args) {
  final packageRoot = Platform.script.resolve('../');
  generateJniBindings(
    Config(
      outputConfig: OutputConfig(
        dartConfig: DartCodeOutputConfig(
          path: packageRoot.resolve('lib/java.g.dart'),
          structure: OutputStructure.singleFile,
        ),
      ),
      androidSdkConfig: AndroidSdkConfig(addGradleDeps: true),
      sourcePath: [packageRoot.resolve('android/app/src/main/java')],
      classes: [
        'de.jsteltze.chesstournamentapp',
        // From gradle's compile classpath
        'io.flutter.plugins',
        // From gradle's compile classpath
        'android.os.Build',
        // from gradle's compile classpath
        'java.util.HashMap',
        // from gradle's compile classpath
      ],
    ),
  );
}
