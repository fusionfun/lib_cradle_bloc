import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_cradle_bloc/lib_cradle_bloc.dart';

void main() {
  const MethodChannel channel = MethodChannel('lib_cradle_bloc');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await LibCradleBloc.platformVersion, '42');
  });
}
