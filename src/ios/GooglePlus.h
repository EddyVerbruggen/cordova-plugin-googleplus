#import <Cordova/CDVPlugin.h>
#import <GooglePlus/GooglePlus.h>

@interface GooglePlus : CDVPlugin<GPPSignInDelegate>

- (void) login:(CDVInvokedUrlCommand*)command;
- (void) trySilentLogin:(CDVInvokedUrlCommand*)command;
- (void) logout:(CDVInvokedUrlCommand*)command;
- (void) share_unused:(CDVInvokedUrlCommand*)command;

@end
