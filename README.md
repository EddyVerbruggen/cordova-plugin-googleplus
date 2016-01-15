# Google+ Cordova/PhoneGap Plugin
by [Eddy Verbruggen](http://twitter.com/eddyverbruggen)

## 0. Index

1. [Description](#1-description)
2. [Screenshots](#2-screenshots)
3. [Google+ API setup](#3-google-api-setup)
4. [Installation (CLI / Plugman)](#4-installation-phonegap-cli--cordova-cli)
5. [Installation (PhoneGap Build)](#5-installation-phonegap-build)
6. [Usage](#6-usage)
7. [Troubleshooting](#7-troubleshooting)
8. [Changelog](#8-changelog)
9. [License](#9-license)

## 1. Description

This plugin allows you to log on with your Google account on iOS and Android.
You will not only get the email address of the user, but also stuff like their full name and gender.

## 2. Screenshots

Android

<img src="https://raw.githubusercontent.com/EddyVerbruggen/cordova-plugin-googleplus/master/screenshots/Android1.png" width="235" height="400"/>&nbsp;
<img src="https://raw.githubusercontent.com/EddyVerbruggen/cordova-plugin-googleplus/master/screenshots/Android2.png" width="235" height="400"/>&nbsp;
<img src="https://raw.githubusercontent.com/EddyVerbruggen/cordova-plugin-googleplus/master/screenshots/Android3.png" width="235" height="400"/>

 iOS

<img src="https://raw.githubusercontent.com/EddyVerbruggen/cordova-plugin-googleplus/master/screenshots/iOS1.png" width="235" height="417"/>&nbsp;
<img src="https://raw.githubusercontent.com/EddyVerbruggen/cordova-plugin-googleplus/master/screenshots/iOS2.png" width="235" height="417"/>&nbsp;
<img src="https://raw.githubusercontent.com/EddyVerbruggen/cordova-plugin-googleplus/master/screenshots/iOS3.png" width="235" height="417"/>&nbsp;

## 3. Google+ API setup
To communicate with Google+ you need to do some tedious setup, sorry.

### iOS
To get your iOS API key, follow Step 1 of [this guide](https://developers.google.com/+/mobile/ios/getting-started)
[get a configuration file here](https://developers.google.com/mobile/add?platform=ios&cntapi=signin).
This `GoogleService-Info.plist` file contains the `REVERSED_CLIENT_ID` you'll need during installation.

### Android
To configure Android, follow Step 2 (Get a configuration file) of [this guide](https://developers.google.com/identity/sign-in/android/start). Once Google Sign-In is enabled Google will automatically create necessary credentials in Developer Console. There is no need to add the generated google-services.json file into your cordova project.

Make sure you execute the `keytool` steps as well or authentication will fail.

## 4. Installation (PhoneGap CLI / Cordova CLI)
This plugin is compatible with [Cordova Plugman](https://github.com/apache/cordova-plugman), compatible with [PhoneGap 3.0 CLI](http://docs.phonegap.com/en/3.0.0/guide_cli_index.md.html#The%20Command-line%20Interface_add_features), here's how it works with the CLI (backup your project first!):

Using the Cordova CLI and [npm](https://www.npmjs.com/package/cordova-plugin-googleplus)
```
$ cordova plugin add cordova-plugin-googleplus --variable REVERSED_CLIENT_ID=myreversedclientid
$ cordova prepare
```

To fetch the latest version from GitHub, use
```
$ cordova plugin add https://github.com/EddyVerbruggen/cordova-plugin-googleplus --variable REVERSED_CLIENT_ID=myreversedclientid
$ cordova prepare
```

GooglePlus.js is brought in automatically. There is no need to change or add anything in your html.

## 5. Installation (PhoneGap Build)
Add this to your config.xml:
```xml
<gap:plugin name="cordova-plugin-googleplus" source="npm">
  <param name="REVERSED_CLIENT_ID" value="myreversedclientid" />
</gap:plugin>
```

## 6. Usage
Check the [demo app](demo) to get you going quickly, or hurt yourself and follow these steps.

Note that none of these methods should be called before [`deviceready`](http://docs.phonegap.com/en/edge/cordova_events_events.md.html#deviceready) has fired.

### isAvailable
You'll want to check this before showing a 'Sign in with Google+' button.

On iOS it will check whether or not the Google+ app is installed. If it's not and you invoke the `login` function,
your app will redirect to Safari [which seems an app rejection reason these days](https://code.google.com/p/google-plus-platform/issues/detail?id=900).

On Android it will check whether or not Google Play Services is available. It's more likely than not that it is.

```javascript
window.plugins.googleplus.isAvailable(
    function (available) {
      if (available) {
        // show the Google+ sign-in button
      }
    }
);
```

### Login
```javascript
window.plugins.googleplus.login(
    {
      'scopes': '... ', // optional space-separated list of scopes, the default is sufficient for login and basic profile info
      'offline': true, // optional, used for Android only - if set to true the plugin will also return the OAuth access token ('oauthToken' param), that can be used to sign in to some third party services that don't accept a Cross-client identity token (ex. Firebase)
      'webApiKey': 'api of web app', // optional API key of your Web application from Credentials settings of your project - if you set it the returned idToken will allow sign in to services like Azure Mobile Services
      // there is no API key for Android; you app is wired to the Google+ API by listing your package name in the google dev console and signing your apk (which you have done in chapter 4)
    },
    function (obj) {
      alert(JSON.stringify(obj)); // do something useful instead of alerting
    },
    function (msg) {
      alert('error: ' + msg);
    }
);
```

Note that if you're only targeting Android you can pass `{}` for the first argument.

The success callback (second argument) gets a JSON object with the following contents, with example data of my Google+ account:
```javascript
 obj.email        // 'eddyverbruggen@gmail.com'
 obj.userId       // user id
 obj.displayName  // 'Eddy Verbruggen'
 obj.imageUrl     // 'http://link-to-my-profilepic.google.com'
 obj.idToken
 obj.oauthToken

 // these are only available on Android at the moment
 obj.gender       // 'male' (other options are 'female' and 'unknown'
 obj.givenName    // 'Eddy'
 obj.middleName   // null (or undefined, depending on the platform)
 obj.familyName   // 'Verbruggen'
 obj.birthday     // '1977-04-22'
 obj.ageRangeMin  // 21 (or null or undefined or a different number)
 obj.ageRangeMax  // null (or undefined or a number)
```

### Try silent login
When the user comes back to your app and you're not sure if he needs to log in,
you can call `trySilentLogin` to try logging him in.

If it succeeds you will get the same object as the `login` function gets,
but if it fails it will not show the authentication dialog to the user.

The code is exactly the same a `login`, except for the function name.
```javascript
window.plugins.googleplus.trySilentLogin(
    {
      'offline': true, // optional and required for Android only - if set to true the plugin will also return the OAuth access token, that can be used to sign in to some third party services that don't accept a Cross-client identity token (ex. Firebase)
      'webApiKey': 'api of web app' // optional API key of your Web application from Credentials settings of your project - if you set it the returned idToken will allow sign in to services like Azure Mobile Services 
    },
    function (obj) {
      alert(JSON.stringify(obj)); // do something useful instead of alerting
    },
    function (msg) {
      alert('error: ' + msg);
    }
);
```

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
This will clear the OAuth2 token and forget which account was used to login.
On Android this will always force the user to authenticate the app again,
on iOS using logout seems to do the job already. Need to investigate this a bit more..
``` javascript
window.plugins.googleplus.disconnect(
    function (msg) {
      alert(msg); // do something useful instead of alerting
    }
);
```

## 7. Troubleshooting
- Q: After authentication I'm not redirected back to my app.
- A: You probably changed the bundle id of your app after installing this plugin. Make sure that (on iOS) the `CFBundleURLTypes` bit in your `.plist` file is the same as the actual bundle id originating from `config.xml`.

- Q: I can't get authentication to work on Android. And why is there no ANDROID API KEY?
- A: On Android you need to execute the `keytool` steps, see the installation instructions for details.

## 8. Changelog
- 4.0.8: Fix for Android 6 where it would crash while asking for permission. Thx #166!
- 4.0.7: Re-added a missing framework for iOS. Thx #168!
- 4.0.6: Updated iOS GoogleSignIn SDK to 2.4.0. Thx #153!
- 4.0.5: Fixed a broken import on iOS
- 4.0.4: Using framework tags again for Android.
- 4.0.3: On iOS `isAvailable` always returns try since that should be fine with the new Google SignIn framework. Re-added imageUrl to the result of SignIn on iOS.
- 4.0.1: Login on Android would crash the app if `isAvailable` was invoked beforehand.
- 4.0.0: Removed the need for `iosApiKey`, reverted Android to Google playservices framework for wider compatibility, documented scopes feature a bit.
- 3.0.0: Using Google Sign-In for iOS, instead of Google+.
- 1.1.0: Added `isAvailable`, for issue [#37](https://github.com/EddyVerbruggen/cordova-plugin-googleplus/issues/37)
- 1.0.0: Initial version supporting iOS and Android

## 9. License

[The MIT License (MIT)](http://www.opensource.org/licenses/mit-license.html)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
