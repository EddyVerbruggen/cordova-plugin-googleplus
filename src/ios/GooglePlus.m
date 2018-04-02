#import "AppDelegate.h"
#import "objc/runtime.h"
#import "GooglePlus.h"

/** Switch to Sign-In SDK.
 @date July 19, 2015
 @author Eddy Verbruggen
 */

/**
  Updates to be more aligned with updated Android version and with Google.
 @date March 15, 2015
 @author Sam Muggleworth (PointSource, LLC)
 */

// need to swap out a method, so swizzling it here
static void swizzleMethod(Class class, SEL destinationSelector, SEL sourceSelector);

@implementation AppDelegate (IdentityUrlHandling)

+ (void)load {
    swizzleMethod([AppDelegate class],
                @selector(application:openURL:sourceApplication:annotation:),
                @selector(identity_application:openURL:sourceApplication:annotation:));

    swizzleMethod([AppDelegate class],
                @selector(application:openURL:options:),
                @selector(indentity_application_options:openURL:options:));
}

/** Google Sign-In SDK
 @date July 19, 2015
 */
- (BOOL)identity_application: (UIApplication *)application
                     openURL: (NSURL *)url
           sourceApplication: (NSString *)sourceApplication
                  annotation: (id)annotation {
    GooglePlus* gp = (GooglePlus*) [self.viewController pluginObjects][@"GooglePlus"];

    if ([gp isSigningIn]) {
        gp.isSigningIn = NO;
        return [[GIDSignIn sharedInstance] handleURL:url sourceApplication:sourceApplication annotation:annotation];
    } else {
        // call super
        return [self identity_application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
    }
}

/**
From https://github.com/EddyVerbruggen/cordova-plugin-googleplus/issues/227#issuecomment-227674026
Fixes issue with G+ login window not closing correctly on ios 9
*/
- (BOOL)indentity_application_options: (UIApplication *)app
            openURL: (NSURL *)url
            options: (NSDictionary *)options
{
    GooglePlus* gp = (GooglePlus*) [self.viewController pluginObjects][@"GooglePlus"];

    if ([gp isSigningIn]) {
        gp.isSigningIn = NO;
        return [[GIDSignIn sharedInstance] handleURL:url
            sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
            annotation:options[UIApplicationOpenURLOptionsAnnotationKey]];
    } else {
        // Other
        return [self indentity_application_options:app openURL:url options:options];
    }
}
@end

@implementation GooglePlus

// If this returns false, you better not call the login function because of likely app rejection by Apple,
// see https://code.google.com/p/google-plus-platform/issues/detail?id=900
// Update: should be fine since we use the GoogleSignIn framework instead of the GooglePlus framework
- (void) isAvailable:(CDVInvokedUrlCommand*)command {
  CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:YES];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) login:(CDVInvokedUrlCommand*)command {
  [[self getGIDSignInObject:command] signIn];
}

/** Get Google Sign-In object
 @date July 19, 2015
 */
- (void) trySilentLogin:(CDVInvokedUrlCommand*)command {
    [[self getGIDSignInObject:command] signInSilently];
}

/** Get Google Sign-In object
 @date July 19, 2015
 @date updated March 15, 2015 (@author PointSource,LLC)
 */
- (GIDSignIn*) getGIDSignInObject:(CDVInvokedUrlCommand*)command {
    _callbackId = command.callbackId;
    NSDictionary* options = command.arguments[0];
    NSString *reversedClientId = [self getreversedClientId];

    if (reversedClientId == nil) {
        CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Could not find REVERSED_CLIENT_ID url scheme in app .plist"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:_callbackId];
        return nil;
    }

    NSString *clientId = [self reverseUrlScheme:reversedClientId];

    NSString* scopesString = options[@"scopes"];
    NSString* serverClientId = options[@"webClientId"];
    NSString *loginHint = options[@"loginHint"];
    BOOL offline = [options[@"offline"] boolValue];
    NSString* hostedDomain = options[@"hostedDomain"];


    GIDSignIn *signIn = [GIDSignIn sharedInstance];
    signIn.clientID = clientId;

    [signIn setLoginHint:loginHint];

    if (serverClientId != nil && offline) {
      signIn.serverClientID = serverClientId;
    }

    if (hostedDomain != nil) {
        signIn.hostedDomain = hostedDomain;
    }

    signIn.uiDelegate = self;
    signIn.delegate = self;

    // default scopes are email and profile
    if (scopesString != nil) {
        NSArray* scopes = [scopesString componentsSeparatedByString:@" "];
        [signIn setScopes:scopes];
    }
    return signIn;
}

- (NSString*) reverseUrlScheme:(NSString*)scheme {
  NSArray* originalArray = [scheme componentsSeparatedByString:@"."];
  NSArray* reversedArray = [[originalArray reverseObjectEnumerator] allObjects];
  NSString* reversedString = [reversedArray componentsJoinedByString:@"."];
  return reversedString;
}

- (NSString*) getreversedClientId {
  NSArray* URLTypes = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleURLTypes"];

  if (URLTypes != nil) {
    for (NSDictionary* dict in URLTypes) {
      NSString *urlName = dict[@"CFBundleURLName"];
      if ([urlName isEqualToString:@"REVERSED_CLIENT_ID"]) {
        NSArray* URLSchemes = dict[@"CFBundleURLSchemes"];
        if (URLSchemes != nil) {
          return URLSchemes[0];
        }
      }
    }
  }
  return nil;
}

- (void) logout:(CDVInvokedUrlCommand*)command {
  [[GIDSignIn sharedInstance] signOut];
  CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"logged out"];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) disconnect:(CDVInvokedUrlCommand*)command {
  [[GIDSignIn sharedInstance] disconnect];
  CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"disconnected"];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) share_unused:(CDVInvokedUrlCommand*)command {
  // for a rainy day.. see for a (limited) example https://github.com/vleango/GooglePlus-PhoneGap-iOS/blob/master/src/ios/GPlus.m
}

#pragma mark - GIDSignInDelegate
/** Google Sign-In SDK
 @date July 19, 2015
 */
- (void)signIn:(GIDSignIn *)signIn didSignInForUser:(GIDGoogleUser *)user withError:(NSError *)error {
    if (error) {
        CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:_callbackId];
    } else {
        NSString *email = user.profile.email;
        NSString *idToken = user.authentication.idToken;
        NSString *accessToken = user.authentication.accessToken;
        NSString *refreshToken = user.authentication.refreshToken;
        NSString *userId = user.userID;
        NSString *serverAuthCode = user.serverAuthCode != nil ? user.serverAuthCode : @"";
        NSURL *imageUrl = [user.profile imageURLWithDimension:120]; // TODO pass in img size as param, and try to sync with Android
        NSDictionary *result = @{
                       @"email"           : email,
                       @"idToken"         : idToken,
                       @"serverAuthCode"  : serverAuthCode,
                       @"accessToken"     : accessToken,
                       @"refreshToken"    : refreshToken,
                       @"userId"          : userId,
                       @"displayName"     : user.profile.name       ? : [NSNull null],
                       @"givenName"       : user.profile.givenName  ? : [NSNull null],
                       @"familyName"      : user.profile.familyName ? : [NSNull null],
                       @"imageUrl"        : imageUrl ? imageUrl.absoluteString : [NSNull null],
                       };

        CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:_callbackId];
    }
}

/** Google Sign-In SDK
 @date July 19, 2015
 */
- (void)signIn:(GIDSignIn *)signIn presentViewController:(UIViewController *)viewController {
    self.isSigningIn = YES;
    [self.viewController presentViewController:viewController animated:YES completion:nil];
}

/** Google Sign-In SDK
 @date July 19, 2015
 */
- (void)signIn:(GIDSignIn *)signIn dismissViewController:(UIViewController *)viewController {
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
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
