#import <GoogleOpenSource/GoogleOpenSource.h>
#import "AppDelegate.h"
#import "GooglePlus.h"

// need to swap out a method, so swizzling it here
static void swizzleMethod(Class class, SEL destinationSelector, SEL sourceSelector);

@implementation AppDelegate (IdentityUrlHandling)

+ (void)load {
  swizzleMethod([AppDelegate class],
                @selector(application:openURL:sourceApplication:annotation:),
                @selector(identity_application:openURL:sourceApplication:annotation:));
}

- (BOOL)identity_application: (UIApplication *)application
                     openURL: (NSURL *)url
           sourceApplication: (NSString *)sourceApplication
                  annotation: (id)annotation {

  GooglePlus* gp = (GooglePlus*)[[self.viewController pluginObjects] objectForKey:@"GooglePlus"];
  
  if ([gp isSigningIn]) {
    gp.isSigningIn = NO;
    return [GPPURLHandler handleURL:url sourceApplication:sourceApplication annotation:annotation];
  } else {
    // call super
    return [self identity_application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
  }
}
@end

@implementation GooglePlus

// If this returns false, you better not call the login function because of likely app rejection by Apple,
// see https://code.google.com/p/google-plus-platform/issues/detail?id=900
- (void) isAvailable:(CDVInvokedUrlCommand*)command {
  BOOL appInstalled = [[UIApplication sharedApplication] canOpenURL: [NSURL URLWithString:@"gplus://"]];
  CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:appInstalled];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) login:(CDVInvokedUrlCommand*)command {
  self.isSigningIn = YES;
  [[self getGooglePlusSignInObject:command] authenticate];
}

- (void) trySilentLogin:(CDVInvokedUrlCommand*)command {
  // trySilentAuthentication doesn't call delegate when it fails, so handle it here
  if (![[self getGooglePlusSignInObject:command] trySilentAuthentication]) {
    CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"no valid token"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
  }
}

- (GPPSignIn*) getGooglePlusSignInObject:(CDVInvokedUrlCommand*)command {
  _callbackId = command.callbackId;
  NSDictionary* options = [command.arguments objectAtIndex:0];
  NSString* apiKey = [options objectForKey:@"iOSApiKey"];
  if (apiKey == nil) {
    CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"iOSApiKey not set"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:_callbackId];
    return nil;
  }
  
  GPPSignIn *signIn = [GPPSignIn sharedInstance];
  signIn.shouldFetchGooglePlusUser = YES;
  signIn.shouldFetchGoogleUserEmail = YES;
  signIn.shouldFetchGoogleUserID = YES;
  signIn.clientID = apiKey;
  signIn.scopes = @[kGTLAuthScopePlusLogin];
  signIn.attemptSSO = YES; // tries to use other installed Google apps
  signIn.delegate = self;
  return signIn;
}

- (void) logout:(CDVInvokedUrlCommand*)command {
  [[GPPSignIn sharedInstance] signOut];
  CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"logged out"];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) disconnect:(CDVInvokedUrlCommand*)command {
  [[GPPSignIn sharedInstance] disconnect];
  CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"disconnected"];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) share_unused:(CDVInvokedUrlCommand*)command {
  // for a rainy day.. see for a (limited) example https://github.com/vleango/GooglePlus-PhoneGap-iOS/blob/master/src/ios/GPlus.m
}

#pragma mark - GPPSignInDelegate
- (void)finishedWithAuth:(GTMOAuth2Authentication *)auth
                   error:(NSError *)error {
  if (error) {
    CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:_callbackId];
  } else {
    NSString *email = [GPPSignIn sharedInstance].userEmail;
    NSString *token = [GPPSignIn sharedInstance].idToken;
    GTMOAuth2Authentication *auth = [[GPPSignIn sharedInstance] authentication];
    NSString *accessToken = auth.accessToken;
    NSString *userId = [GPPSignIn sharedInstance].userID;
    GTLPlusPerson *person = [GPPSignIn sharedInstance].googlePlusUser;
    NSDictionary *result;
    
    if (person == nil) {
      result = @{
                 @"email" : email
                 };
    } else {
      result = @{
                 @"email"       : email,
                 @"idToken"     : token,
                 @"oauthToken"  : accessToken,
                 @"userId"      : userId,
                 @"displayName" : person.displayName ?: [NSNull null],
                 @"gender"      : person.gender ?: [NSNull null],
                 @"imageUrl"    : (person.image != nil && person.image.url != nil) ? person.image.url : [NSNull null],
                 @"givenName"   : (person.name != nil && person.name.givenName != nil) ? person.name.givenName : [NSNull null],
                 @"middleName"  : (person.name != nil && person.name.middleName != nil) ? person.name.middleName : [NSNull null],
                 @"familyName"  : (person.name != nil && person.name.familyName != nil) ? person.name.familyName : [NSNull null],
                 @"ageRangeMin" : person.ageRange && person.ageRange.min ? person.ageRange.min : [NSNull null],
                 @"ageRangeMax" : person.ageRange && person.ageRange.max ? person.ageRange.max : [NSNull null],
                 @"birthday"    : person.birthday ?: [NSNull null]
                 };
    }
    CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:_callbackId];
  }
}

#pragma mark Swizzling

@end

static void swizzleMethod(Class class, SEL destinationSelector, SEL sourceSelector) {
  Method destinationMethod = class_getInstanceMethod(class, destinationSelector);
  Method sourceMethod = class_getInstanceMethod(class, sourceSelector);
  
  // If the method doesn't exist, add it.  If it does exist, replace it with the given implementation.
  if (class_addMethod(class, destinationSelector, method_getImplementation(sourceMethod), method_getTypeEncoding(sourceMethod))) {
    class_replaceMethod(class, destinationSelector, method_getImplementation(destinationMethod), method_getTypeEncoding(destinationMethod));
  } else {
    method_exchangeImplementations(destinationMethod, sourceMethod);
  }
}
