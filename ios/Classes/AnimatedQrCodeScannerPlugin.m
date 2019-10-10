#import "AnimatedQrCodeScannerPlugin.h"
#import <animated_qr_code_scanner/animated_qr_code_scanner-Swift.h>

@implementation AnimatedQrCodeScannerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftAnimatedQrCodeScannerPlugin registerWithRegistrar:registrar];
}
@end
