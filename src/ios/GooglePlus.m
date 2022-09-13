#import "AppDelegate.h"
#import "objc/runtime.h"
#import "GooglePlus.h"

@implementation GooglePlus

- (void)pluginInitialize
{
    NSLog(@"GooglePlus pluginInitizalize");
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleOpenURL:) name:CDVPluginHandleOpenURLNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleOpenURLWithAppSourceAndAnnotation:) name:CDVPluginHandleOpenURLWithAppSourceAndAnnotationNotification object:nil];
}

- (void)handleOpenURL:(NSNotification*)notification
{
    // no need to handle this handler, we dont have an sourceApplication here, which is required by GIDSignIn handleURL
}

- (void)handleOpenURLWithAppSourceAndAnnotation:(NSNotification*)notification
{
    NSMutableDictionary * options = [notification object];

    NSURL* url = options[@"url"];

    NSString* possibleReversedClientId = [url.absoluteString componentsSeparatedByString:@":"].firstObject;

    if ([possibleReversedClientId isEqualToString:self.getreversedClientId] && self.isSigningIn) {
        self.isSigningIn = NO;
        [GIDSignIn.sharedInstance handleURL:url];
    }
}


- (void) login:(CDVInvokedUrlCommand*)command {
    _callbackId = command.callbackId;
    NSString *reversedClientId = [self getreversedClientId];

    if (reversedClientId == nil) {
        NSDictionary *errorDetails = @{@"status": @"error", @"message": @"Could not find REVERSED_CLIENT_ID url scheme in app .plist"};
        CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[self toJSONString:errorDetails]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:_callbackId];
        return;
    }

    NSString *clientId = [self reverseUrlScheme:reversedClientId];

    GIDConfiguration *config = [[GIDConfiguration alloc] initWithClientID:clientId];

    GIDSignIn *signIn = GIDSignIn.sharedInstance;

    [signIn signInWithConfiguration:config presentingViewController:self.viewController callback:^(GIDGoogleUser * _Nullable user, NSError * _Nullable error) {
        if (error) {
            NSDictionary *errorDetails = @{@"status": @"error", @"message": error.localizedDescription};
            CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[self toJSONString:errorDetails]];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self->_callbackId];
        } else {
            NSString *email = user.profile.email;
            NSString *userId = user.userID;
            NSURL *imageUrl = [user.profile imageURLWithDimension:120]; // TODO pass in img size as param, and try to sync with Android
            NSDictionary *result = @{
                           @"email"           : email,
                           @"userId"          : userId,
                           @"idToken"         : user.authentication.idToken,
                           @"displayName"     : user.profile.name       ? : [NSNull null],
                           @"givenName"       : user.profile.givenName  ? : [NSNull null],
                           @"familyName"      : user.profile.familyName ? : [NSNull null],
                           @"imageUrl"        : imageUrl ? imageUrl.absoluteString : [NSNull null],
                           };

            CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: [self toJSONString:result]];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self->_callbackId];
        }
    }];
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
    [GIDSignIn.sharedInstance signOut];
    NSDictionary *details = @{@"status": @"success", @"message": @"Logged out"};
    CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[self toJSONString:details]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) disconnect:(CDVInvokedUrlCommand*)command {
    [GIDSignIn.sharedInstance disconnectWithCallback:^(NSError * _Nullable error) {
        if(error == nil) {
            NSDictionary *details = @{@"status": @"success", @"message": @"Disconnected"};
            CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[self toJSONString:details]];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        } else {
            NSDictionary *details = @{@"status": @"error", @"message": [error localizedDescription]};
            CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[self toJSONString:details]];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
    }];
}

- (void) isSignedIn:(CDVInvokedUrlCommand*)command {
    bool isSignedIn = [GIDSignIn.sharedInstance currentUser] != nil;
    NSDictionary *details = @{@"status": @"success", @"message": (isSignedIn) ? @"true" : @"false"};
    CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[self toJSONString:details]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

#pragma mark - GIDSignInDelegate
- (void)signIn:(GIDSignIn *)signIn didSignInForUser:(GIDGoogleUser *)user withError:(NSError *)error {

}

- (void)signIn:(GIDSignIn *)signIn presentViewController:(UIViewController *)viewController {
    self.isSigningIn = YES;
    [self.viewController presentViewController:viewController animated:YES completion:nil];
}

- (void)signIn:(GIDSignIn *)signIn dismissViewController:(UIViewController *)viewController {
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
}

- (NSString*)toJSONString:(NSDictionary*)dictionaryOrArray {
    NSError *error;
         NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionaryOrArray
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
         if (! jsonData) {
            NSLog(@"%s: error: %@", __func__, error.localizedDescription);
            return @"{}";
         } else {
            return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
         }
}

@end
