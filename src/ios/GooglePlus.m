#import "GooglePlus.h"
#import <GoogleOpenSource/GoogleOpenSource.h>

@implementation GooglePlus

NSString* theCallbackId;

- (void) login:(CDVInvokedUrlCommand*)command {
  [[self getGooglePlusSignInObject:command] authenticate];
}

- (void) trySilentLogin:(CDVInvokedUrlCommand*)command {
  // trySilentAuthentication doesn't call delegate when it fails, so handle it here
  if (![[self getGooglePlusSignInObject:command] trySilentAuthentication]) {
    CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"no valid token"];
    [self writeJavascript:[pluginResult toErrorCallbackString:command.callbackId]];
  }
}

- (GPPSignIn*) getGooglePlusSignInObject:(CDVInvokedUrlCommand*)command {
  theCallbackId = command.callbackId;
  NSDictionary* options = [command.arguments objectAtIndex:0];
  NSString* apiKey = [options objectForKey:@"iOSApiKey"];
  if (apiKey == nil) {
    CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"iOSApiKey not set"];
    [self writeJavascript:[pluginResult toErrorCallbackString:theCallbackId]];
    return nil;
  }

  GPPSignIn *signIn = [GPPSignIn sharedInstance];
  signIn.shouldFetchGooglePlusUser = YES;
  signIn.shouldFetchGoogleUserEmail = YES;
  
//  NSString *googlePlusApiKeyFromPlist = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"GooglePlusApiKey"];
  signIn.clientID = apiKey;
  signIn.scopes = @[ kGTLAuthScopePlusLogin ];
  signIn.attemptSSO = YES; // tries to use other installed Google apps
  signIn.delegate = self;
  return signIn;
}

- (void) logout:(CDVInvokedUrlCommand*)command {
  [[GPPSignIn sharedInstance] signOut];
  CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"signed out"];
  [self writeJavascript:[pluginResult toSuccessCallbackString:command.callbackId]];
}

- (void) share_unused:(CDVInvokedUrlCommand*)command {
  // for a rainy day.. see for a (limited) example https://github.com/vleango/GooglePlus-PhoneGap-iOS/blob/master/src/ios/GPlus.m
}

#pragma mark - GPPSignInDelegate
- (void)finishedWithAuth:(GTMOAuth2Authentication *)auth
                   error:(NSError *)error {
  if (error) {
    CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
    [self writeJavascript:[pluginResult toErrorCallbackString:theCallbackId]];
  } else {
//    NSString *email = [GPPSignIn sharedInstance].userEmail;
    GTLPlusPerson *person = [GPPSignIn sharedInstance].googlePlusUser;

    // TODO custom response, or pass it all? passing it all for now
    NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                  auth.parameters, @"auth",
                                  person.JSON, @"person",
                                  nil];
    
    CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result];
    [self writeJavascript:[pluginResult toSuccessCallbackString:theCallbackId]];
  }
}

@end