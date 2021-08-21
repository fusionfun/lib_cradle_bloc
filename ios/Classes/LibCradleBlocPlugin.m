#import "LibCradleBlocPlugin.h"
#if __has_include(<lib_cradle_bloc/lib_cradle_bloc-Swift.h>)
#import <lib_cradle_bloc/lib_cradle_bloc-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "lib_cradle_bloc-Swift.h"
#endif

@implementation LibCradleBlocPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftLibCradleBlocPlugin registerWithRegistrar:registrar];
}
@end
