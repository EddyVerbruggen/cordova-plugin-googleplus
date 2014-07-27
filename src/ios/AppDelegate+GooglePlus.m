#import "AppDelegate+GooglePlus.h"
#import <objc/runtime.h>
#import "GooglePlus.h"

@implementation AppDelegate (GooglePlus)

#pragma mark - Overridden Methods

- (BOOL)application:(UIApplication*)application openURL:(NSURL*)url sourceApplication:(NSString*)sourceApplication annotation:(id)annotation {
  if (!url) {
    return NO;

  } else if ([url.parameterString rangeOfString:@"oauth2callback"].location != NSNotFound) {
    return [GPPURLHandler handleURL:url sourceApplication:sourceApplication annotation:annotation];

  } else {
    // impl of 'super'

    // calls into javascript global function 'handleOpenURL'
    NSString* jsString = [NSString stringWithFormat:@"handleOpenURL(\"%@\");", url];
    [self.viewController.webView stringByEvaluatingJavaScriptFromString:jsString];
    
    // all plugins will get the notification, and their handlers will be called
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:CDVPluginHandleOpenURLNotification object:url]];
    
    return YES;
  }
}

@end