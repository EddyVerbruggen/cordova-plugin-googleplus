# Google Sign-In Cordova/PhoneGap Plugin
by [Eddy Verbruggen](http://twitter.com/eddyverbruggen),
with great assistance from Sam Muggleworth ([PointSource, LLC](https://github.com/PointSource))

## 0. Index

1. [Description](#1-description)
2. [Screenshots](#2-screenshots)
3. [Google API setup](#3-google-api-setup)
4. [Installation (CLI / Plugman)](#4-installation-phonegap-cli--cordova-cli)
5. [Installation (PhoneGap Build)](#5-installation-phonegap-build)
6. [Usage](#6-usage)
7. [Exchanging the `idToken`](#7-exchanging-the-idtoken)
8. [Exchanging the `serverAuthCode`](#8-exchanging-the-serverauthcode)
9. [Troubleshooting](#9-troubleshooting)
10. [Changelog](#10-changelog)

## 1. Description

This plugin allows you to authenticate and identify users with [Google Sign-In](https://developers.google.com/identity/) on [iOS](https://developers.google.com/identity/sign-in/ios/) and [Android](https://developers.google.com/identity/sign-in/android/).
Out of the box, you'll get email, display name, given name, family name, profile picture url, and user id.
You can also configure it to get an [idToken](#7-exchanging-the-idtoken) and [serverAuthCode](#8-exchanging-the-serverauthcode).

This plugin only wraps access to the Google Sign-In API. Further API access should be implemented per use-case, per developer.

## 2. Screenshots

Android

<img src="https://raw.githubusercontent.com/EddyVerbruggen/cordova-plugin-googleplus/master/screenshots/Android1.png" width="235" height="400"/>&nbsp;
<img src="https://raw.githubusercontent.com/EddyVerbruggen/cordova-plugin-googleplus/master/screenshots/Android2.png" width="235" height="400"/>&nbsp;
<img src="https://raw.githubusercontent.com/EddyVerbruggen/cordova-plugin-googleplus/master/screenshots/Android3.png" width="235" height="400"/>

 iOS

<img src="https://raw.githubusercontent.com/EddyVerbruggen/cordova-plugin-googleplus/master/screenshots/iOS1.png" width="235" height="417"/>&nbsp;
<img src="https://raw.githubusercontent.com/EddyVerbruggen/cordova-plugin-googleplus/master/screenshots/iOS2.png" width="235" height="417"/>&nbsp;
<img src="https://raw.githubusercontent.com/EddyVerbruggen/cordova-plugin-googleplus/master/screenshots/iOS3.png" width="235" height="417"/>&nbsp;

## 3. Google API setup
To communicate with Google you need to do some tedious setup, sorry.

It is (strongly) recommended that you use the same project for both iOS and Android.

### Before you proceed
Go into your `config.xml` and make sure that your package name (i.e. the app ID) is what you want it to be. Use this package name when setting up iOS and Android in the following steps! If you don't, you will likely get a 12501, 'user cancelled' error despite never cancelling the log in process.

This step is _especially_ important if you are using a framework such as Ionic to scaffold out your project. When you create the project, the `config.xml` has a placeholder packagename, e.g. com.ionic.*, so you can start developing right away.

```xml
<?xml version='1.0' encoding='utf-8'?>
<widget id="** REPLACE THIS VALUE **" ...>
...
</widget>
```

### Browser
Browser platform require a valid `WEB_APPLICATION_CLIENT_ID` that generated at [Google Developer Console](https://console.developers.google.com/).
Ensure you have added your url address (example: `http://localhost:3000`) to **Authorized JavaScript origins** section.
See [this screenshot for example](http://pix.toile-libre.org/upload/original/1508064473.png)

### iOS
To get your iOS `REVERSED_CLIENT_ID`, [generate a configuration file here](https://developers.google.com/mobile/add?platform=ios&cntapi=signin).
This `GoogleService-Info.plist` file contains the `REVERSED_CLIENT_ID` you'll need during installation. _This value is only needed for iOS._

The `REVERSED_CLIENT_ID` is also known as the "iOS URL Scheme" on the Developer's Console.

Login on iOS takes the user to a [SafariViewController](https://developer.apple.com/library/ios/documentation/SafariServices/Reference/SFSafariViewController_Ref/) through the Google SDK, instead of the separate Safari browser.

### Android
To configure Android, [generate a configuration file here](https://developers.google.com/mobile/add?platform=android&cntapi=signin). Once Google Sign-In is enabled Google will automatically create necessary credentials in Developer Console. There is no need to add the generated google-services.json file into your cordova project.

Make sure you execute the `keytool` steps as explained [here](https://developers.google.com/drive/android/auth) or authentication will fail (do this for both release and debug keystores).

IMPORTANT:
* The step above, about `keytool`, show 2 types of certificate fingerprints, the **Release** and the **Debug**, when generating the configuration file, it's better to use the **Debug** certificate fingerprint, after that, you have to go on [Google Credentials Manager](https://console.developers.google.com/apis/credentials), and manually create a credential for **OAuth2 client** with your **Release** certificate fingerprint. This is necessary to your application work on both Development and Production releases.
* Ensure that you are using the correct alias name while generating the fingerprint.
```
$ keytool -exportcert -keystore <path-to-debug-or-production-keystore> -list -v -alias <alias-name>
```
Login on Android will use the accounts signed in on the user's device.

#### Publishing your app in Google Play Store

Google re-signs your app with a different certificate when you publish it in the Play Store. Once your app is published, copy the SHA-1 fingerprint of the "App signing certificate", found in the "App signing" section under "Release Management", in [Google Play Console](https://play.google.com/apps/publish/). Paste this fingerprint in the Release OAuth client ID in [Google Credentials Manager](https://console.developers.google.com/apis/credentials).

### Web Client Id

If you want to get an `idToken` or `serverAuthCode` back from the Sign In Process, you will need to pass the client ID for your project's web application. This can be found on your project's API credentials page on the [Google Developer's Console](https://console.developers.google.com/).

## 4. Installation (PhoneGap CLI / Cordova CLI)
This plugin is compatible with:
* [Cordova Plugman](https://github.com/apache/cordova-plugman)
* [PhoneGap 3.0 CLI](http://docs.phonegap.com/en/3.0.0/guide_cli_index.md.html#The%20Command-line%20Interface_add_features)
* [Ionic](http://ionic.io/) ***(must use the Cordova CLI)***
* [Meteor JS](https://atmospherejs.com/hedcet/cordova-google-plus-native-sign-in)

Here's how it works (backup your project first!):

Using the Cordova CLI and [npm](https://www.npmjs.com/package/cordova-plugin-googleplus):
```
$ cordova plugin add cordova-plugin-googleplus --save --variable REVERSED_CLIENT_ID=myreversedclientid --variable WEB_APPLICATION_CLIENT_ID=mywebapplicationclientid
$ cordova prepare
```

Using the Cordova CLI to fetch the latest version from GitHub:
```
$ cordova plugin add https://github.com/EddyVerbruggen/cordova-plugin-googleplus --save --variable REVERSED_CLIENT_ID=myreversedclientid  --variable WEB_APPLICATION_CLIENT_ID=mywebapplicationclientid
$ cordova prepare
```

IMPORTANT:

* _Please note that `myreversedclientid` is a place holder for the reversed clientId you find in your iOS configuration file. Do not surround this value with quotes. **(iOS only Applications)**_

* _If you are building a hybrid application **(iOS and Android)**, or an Android application, you have to replace `myreversedclientid` with the reverse value of Client ID in your **Release** credential generated on step 3, on [Google Developer's Console](https://console.developers.google.com/), this will be: **"com.googleusercontent.apps.`uniqueId`"**, without quotes. Example: '123-abc123.apps.googleusercontent.com' becomes 'com.googleusercontent.apps.123-abc123'._

* `myreversedclientid` is a place holder for Oauth Client ID specifically generated for web application in your [Google Developer's Console](https://console.developers.google.com/).

GooglePlus.js is brought in automatically. There is no need to change or add anything in your html.

## 5. Installation (PhoneGap Build)
Add this to your config.xml:

For the (stable) NPM Version:
```xml
<plugin name="cordova-plugin-googleplus" source="npm">
  <variable name="REVERSED_CLIENT_ID" value="myreversedclientid" />
  <variable name="WEB_APPLICATION_CLIENT_ID" value="mywebapplicationclientid" />
</plugin>
```

For the latest version from Git (not recommended):
```xml
<plugin spec="https://github.com/EddyVerbruggen/cordova-plugin-googleplus.git" source="git">
  <variable name="REVERSED_CLIENT_ID" value="myreversedclientid" />
  <variable name="WEB_APPLICATION_CLIENT_ID" value="mywebapplicationclientid" />
<plugin>
```

## 6. Usage
Check the [demo app](demo) to get you going quickly, or hurt yourself and follow these steps.

Note that none of these methods should be called before [`deviceready`](https://cordova.apache.org/docs/en/latest/cordova/events/events.deviceready.html) has fired.

Example:
```javascript
document.addEventListener('deviceready', deviceReady, false);

function deviceReady() {
    //I get called when everything's ready for the plugin to be called!
    console.log('Device is ready!');
    window.plugins.googleplus.trySilentLogin(...);
}
```

### isAvailable
3/31/16: This method is no longer required to be checked first. It is kept for code orthoganality.

### Login

The login function walks the user through the Google Auth process. All parameters are optional, however there are a few caveats.

To get an `idToken` on Android, you ***must*** pass in your `webClientId` (a frequent mistake is to supply Android Client ID). On iOS, the `idToken` is included in the sign in result by default.

To get a `serverAuthCode`, you must pass in your `webClientId` _and_ set `offline` to true. If offline is true, but no webClientId is provided, the `serverAuthCode` will _**NOT**_ be requested.

The default scopes requested are `profile` and `email` (always requested). To request other scopes, add them as a **space-separated list** to the `scopes` parameter. They will be requested exactly as passed in. Refer to the [Google Scopes](https://developers.google.com/identity/protocols/googlescopes) documentation for info on valid scopes that can be requested. For example, `'scope': 'https://www.googleapis.com/auth/youtube https://www.googleapis.com/auth/tasks'`.

Naturally, in order to use any additional scopes or APIs, they will need to be activated in your project Developer's Console.

##### Usage
```javascript
window.plugins.googleplus.login(
    {
      'scopes': '... ', // optional, space-separated list of scopes, If not included or empty, defaults to `profile` and `email`.
      'webClientId': 'client id of the web app/server side', // optional clientId of your Web application from Credentials settings of your project - On Android, this MUST be included to get an idToken. On iOS, it is not required.
      'offline': true // optional, but requires the webClientId - if set to true the plugin will also return a serverAuthCode, which can be used to grant offline access to a non-Google server
    },
    function (obj) {
      alert(JSON.stringify(obj)); // do something useful instead of alerting
    },
    function (msg) {
      alert('error: ' + msg);
    }
);
```

The success callback (second argument) gets a JSON object with the following contents, with example data of my Google account:
```javascript
 obj.email          // 'eddyverbruggen@gmail.com'
 obj.userId         // user id
 obj.displayName    // 'Eddy Verbruggen'
 obj.familyName     // 'Verbruggen'
 obj.givenName      // 'Eddy'
 obj.imageUrl       // 'http://link-to-my-profilepic.google.com'
 obj.idToken        // idToken that can be exchanged to verify user identity.
 obj.serverAuthCode // Auth code that can be exchanged for an access token and refresh token for offline access
 obj.accessToken    // OAuth2 access token
```

Additional user information is available by use case. Add the scopes needed to the scopes option then return the info to the result object being created in the `handleSignInResult` and `didSignInForUser` functions on Android and iOS, respectively.

On Android, the error callback (third argument) receives an error status code if authentication was not successful. A description of those status codes can be found on Google's android developer website at [GoogleSignInStatusCodes](https://developers.google.com/android/reference/com/google/android/gms/auth/api/signin/GoogleSignInStatusCodes).

On iOS, the error callback will include an [NSError localizedDescription](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSError_Class/).

### Try silent login
You can call `trySilentLogin` to check if they're already signed in to the app and sign them in silently if they are.

If it succeeds you will get the same object as the `login` function gets,
but if it fails it will not show the authentication dialog to the user.

Calling `trySilentLogin` is done the same as `login`, except for the function name.
```javascript
window.plugins.googleplus.trySilentLogin(
    {
      'scopes': '... ', // optional - space-separated list of scopes, If not included or empty, defaults to `profile` and `email`.
      'webClientId': 'client id of the web app/server side', // optional - clientId of your Web application from Credentials settings of your project - On Android, this MUST be included to get an idToken. On iOS, it is not required.
      'offline': true, // Optional, but requires the webClientId - if set to true the plugin will also return a serverAuthCode, which can be used to grant offline access to a non-Google server
    },
    function (obj) {
      alert(JSON.stringify(obj)); // do something useful instead of alerting
    },
    function (msg) {
      alert('error: ' + msg);
    }
);
```

It is strongly recommended that trySilentLogin is implemented with the same options as login, to avoid any potential complications.

### logout
This will clear the OAuth2 token.
``` javascript
window.plugins.googleplus.logout(
    function (msg) {
      alert(msg); // do something useful instead of alerting
    }
);
```

### disconnect
This will clear the OAuth2 token, forget which account was used to login, and disconnect that account from the app. This will require the user to allow the app access again next time they sign in. Be aware that this effect is not always instantaneous. It can take time to completely disconnect.
``` javascript
window.plugins.googleplus.disconnect(
    function (msg) {
      alert(msg); // do something useful instead of alerting
    }
);
```

## 7. Exchanging the `idToken`

Google Documentation for Authenticating with a Backend Server
- [Web](https://developers.google.com/identity/sign-in/web/backend-auth)
- [Android](https://developers.google.com/identity/sign-in/android/backend-auth)
- [iOS](https://developers.google.com/identity/sign-in/ios/backend-auth)

As the above articles mention, the `idToken` can be exchanged for user information to confirm the users identity.

_Note: Google does not want user identity data sent directly to a server. The idToken is their preferred method to send that data securely and safely, as it must be verified through their servers in order to unpack._

This has several uses. On the client-side, it can be a way to get doubly confirm the user identity, or it can be used to get details such as the email host domain. The server-side is where the `idToken` really hits its stride. It is an easy way to confirm the users identity before allowing them access to that servers resources or before exchanging the `serverAuthCode` for an access and refresh token (see the next section).

If your server-side only needs identity, and not additional account access, this is a secure and simple way to supply that information.

## 8. Exchanging the `serverAuthCode`

Google Documentation for Enabling Server-Side Access
- [Web](https://developers.google.com/identity/protocols/OAuth2WebServer#handlingresponse)
- [Android](https://developers.google.com/identity/sign-in/android/offline-access)
- [iOS](https://developers.google.com/identity/sign-in/ios/offline-access)

As the above articles mention, the `serverAuthCode` is an item that can be exchanged for an access and refresh token. Unlike the `idToken`, this allows the server-side to have direct access to the users Google account.

You have a couple options when it comes to this exchange: you can use the Google REST Apis to get those in the hybrid app itself or you can send the code to your backend server to be exchanged there, using whatever method necessary (Google provides examples for Java, Python, and JS/HTTP).

As stated before, this plugin is all about user authentication and identity, so any use of the user's account beyond that needs to be implemented per use case, per application.

## 9. Troubleshooting
- Q: I can't get authentication to work on Android. And why is there no ANDROID API KEY?
- A: On Android you need to execute the `keytool` steps, see the installation instructions for details.

- Q: After following the `keytool` steps, I still can't get authentication to work on Android. I'm having a "10 error"!!!
- A: You need to get the SHA 1 cert from your apk file. Run: `keytool -list -printcert -jarfile <your apk>` and copy the SHA 1 to your Android Client ID on Google Console.

- Q: OMG $@#*! the Android build is failing
- A: You need to have _Android Support Repository_ and _Android Support Library_ installed in the Android SDK manager. Make sure you're using a fairly up to date version of those.

- Q: Why isn't this working on my Android Emulator???
- A: Make sure you are using a Virtual Device running with a **Google APIs target and/or a Google APIs CPU**!

## 10. Changelog
- 5.3.0: Browser platform added.
- 5.0.3: Added the convenience method `getSigningCertificateFingerprint` to retrieve the Android cert fingerprint which is required in the Google Developer Console.
- 5.0.2: Require linking against `SafariServices` and `CoreText` frameworks on iOS as per Google's recommendation. Added `loginHint` on iOS.
- 5.0.0: Android GoogleSignIn SDK (See #193), iOS SDK 4.0.0, iOS compatibility with Facebook authentication plugins, added `familyName` and `givenName`.
- 4.0.8: Fix for Android 6 where it would crash while asking for permission. Thx #166!
- 4.0.7: Re-added a missing framework for iOS. Thx #168!
- 4.0.6: Updated iOS GoogleSignIn SDK to 2.4.0. Thx #153!
- 4.0.5: Fixed a broken import on iOS.
- 4.0.4: Using framework tags again for Android
- 4.0.3: On iOS `isAvailable` always returns try since that should be fine with the new Google Sign-In framework. Re-added imageUrl to the result of Sign-In on iOS.
- 4.0.1: Login on Android would crash the app if `isAvailable` was invoked beforehand.
- 4.0.0: Removed the need for `iosApiKey`, reverted Android to Google playservices framework for wider compatibility, documented scopes feature a bit.
- 3.0.0: Using Google Sign-In for iOS, instead of Google+.
- 1.1.0: Added `isAvailable`, for issue [#37](https://github.com/EddyVerbruggen/cordova-plugin-googleplus/issues/37)
- 1.0.0: Initial version supporting iOS and Android.
