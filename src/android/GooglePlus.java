package nl.xservices.plugins;

import java.io.IOException;

import android.app.Activity;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.IntentSender;
import android.os.AsyncTask;
import android.os.Bundle;

import com.google.android.gms.auth.GoogleAuthException;
import com.google.android.gms.auth.GoogleAuthUtil;
import com.google.android.gms.auth.UserRecoverableAuthException;
import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.Scopes;
import com.google.android.gms.common.api.GoogleApiClient;
import com.google.android.gms.common.api.GoogleApiClient.ConnectionCallbacks;
import com.google.android.gms.common.api.GoogleApiClient.OnConnectionFailedListener;
import com.google.android.gms.common.api.ResultCallback;
import com.google.android.gms.common.api.Status;
import com.google.android.gms.plus.Plus;
import com.google.android.gms.plus.model.people.Person;

import org.apache.cordova.*;
import org.json.JSONException;
import org.json.JSONObject;

public class GooglePlus extends CordovaPlugin implements ConnectionCallbacks, OnConnectionFailedListener {

  public static final String ACTION_LOGIN = "login";
  public static final String ACTION_TRY_SILENT_LOGIN = "trySilentLogin";
  public static final String ACTION_LOGOUT = "logout";
  public static final String ACTION_DISCONNECT = "disconnect";

  // Wraps our service connection to Google Play services and provides access to the users sign in state and Google APIs
  private GoogleApiClient mGoogleApiClient;
  private CallbackContext savedCallbackContext;
  private boolean trySilentLogin;
  private boolean loggingOut;

  @Override
  public void initialize(CordovaInterface cordova, CordovaWebView webView) {
    super.initialize(cordova, webView);
    mGoogleApiClient = buildGoogleApiClient();
  }

  @Override
  public boolean execute(String action, CordovaArgs args, CallbackContext callbackContext) throws JSONException {
    this.savedCallbackContext = callbackContext;

    if (ACTION_LOGIN.equals(action)) {
      this.trySilentLogin = false;
      mGoogleApiClient.connect();

    } else if (ACTION_TRY_SILENT_LOGIN.equals(action)) {
      this.trySilentLogin = true;
      mGoogleApiClient.connect();

    } else if (ACTION_LOGOUT.equals(action)) {
      try {
        Plus.AccountApi.clearDefaultAccount(mGoogleApiClient);
        mGoogleApiClient.disconnect();
        // needed in onActivityResult when the connect method below comes back
        loggingOut = true;
        mGoogleApiClient = buildGoogleApiClient();
        mGoogleApiClient.connect();
      } catch (IllegalStateException e) {
        savedCallbackContext.success("logged out");
      }

    } else if (ACTION_DISCONNECT.equals(action)) {
      disconnect();
    }
    return true;
  }

  private void disconnect() {
    try {
      Plus.AccountApi.revokeAccessAndDisconnect(mGoogleApiClient)
          .setResultCallback(new ResultCallback<Status>() {
            @Override
            public void onResult(Status status) {
              // mGoogleApiClient is now disconnected and access has been revoked.
              // Don't care if it was disconnected already (status != success).
              mGoogleApiClient = buildGoogleApiClient();
              savedCallbackContext.success("disconnected");
            }
          });
    } catch (IllegalStateException e) {
      savedCallbackContext.success("disconnected");
    }
  }

  private GoogleApiClient buildGoogleApiClient() {
    return new GoogleApiClient.Builder(webView.getContext())
        .addConnectionCallbacks(this)
        .addOnConnectionFailedListener(this)
        .addApi(Plus.API, Plus.PlusOptions.builder().build())
        .addScope(Plus.SCOPE_PLUS_LOGIN)
        .build();
  }

  @SuppressWarnings({ "unchecked", "rawtypes" })
  private void resolveToken(final String email, final JSONObject result) {
	  final Context context = this.cordova.getActivity().getApplicationContext();
	  final String scope = "oauth2:" + Scopes.PLUS_LOGIN;

	  AsyncTask task = new AsyncTask() {
        @Override
        protected Object doInBackground(Object... params) {
          String scope = "oauth2:" + Scopes.PLUS_LOGIN;
          try {
            // Retrieve the oauth token
            String token = GoogleAuthUtil.getToken(context, email, scope);
            result.put("idToken", token);
            savedCallbackContext.success(result);

          } catch (UserRecoverableAuthException e) {
            // This error is recoverable, so we could fix this
            // by displaying the intent to the user.
            savedCallbackContext.error("result recoverable error, error: " +
                                       e.getMessage());

          } catch (IOException e) {
            savedCallbackContext.error("result IO error, error: " +
                                       e.getMessage());

          } catch (GoogleAuthException e) {
            savedCallbackContext.error("result auth error, error: " +
                                       e.getMessage());

          } catch (JSONException e) {
            savedCallbackContext.error("result auth error, error: " +
                                       e.getMessage());

          }
          return null;
        }
      };
		task.execute((Void) null);
  }

  /**
   * onConnected is called when our Activity successfully connects to Google
   * Play services.  onConnected indicates that an account was selected on the
   * device, that the selected account has granted any requested permissions to
   * our app and that we were able to establish a service connection to Google
   * Play services.
   */
  @Override
  public void onConnected(Bundle connectionHint) {
    final String email = Plus.AccountApi.getAccountName(mGoogleApiClient);
    final Person user = Plus.PeopleApi.getCurrentPerson(mGoogleApiClient);

    final JSONObject result = new JSONObject();
    try {
      result.put("email", email);
      // in case there was no internet connection, this may be null
      if (user != null) {
        result.put("userId", user.getId());
        result.put("displayName", user.getDisplayName());
        result.put("gender", getGender(user.getGender()));
        if (user.getImage() != null) {
          result.put("imageUrl", user.getImage().getUrl());
        }
        if (user.getName() != null) {
          result.put("givenName", user.getName().getGivenName());
          result.put("middleName", user.getName().getMiddleName());
          result.put("familyName", user.getName().getFamilyName());
          if (user.hasAgeRange()) {
            if (user.getAgeRange().hasMin()) {
              result.put("ageRangeMin", user.getAgeRange().getMin());
            }
            if (user.getAgeRange().hasMax()) {
              result.put("ageRangeMax", user.getAgeRange().getMax());
            }
          }
          if (user.hasBirthday()) {
            result.put("birthday", user.getBirthday());
          }
        }
      }
      resolveToken(email, result);
    } catch (JSONException e) {
      savedCallbackContext.error("result parsing trouble, error: " + e.getMessage());
    }
  }

  // same as iOS values
  private static String getGender(int gender) {
    switch (gender) {
      case 0:
        return "male";
      case 1:
        return "female";
      default:
        return "other";
    }
  }

  @Override
  public void onConnectionSuspended(int constantInClass_ConnectionCallbacks) {
    this.savedCallbackContext.error("connection trouble, code: " + constantInClass_ConnectionCallbacks);
  }

  /**
   * onConnectionFailed is called when our Activity could not connect to Google Play services.
   * onConnectionFailed indicates that the user needs to select an account, grant permissions or resolve an error in order to sign in.
   */
  @Override
  public void onConnectionFailed(ConnectionResult result) {
    if (result.getErrorCode() == ConnectionResult.SERVICE_MISSING) { // e.g. emulator without play services installed
      this.savedCallbackContext.error("service not available");
    } else if (loggingOut) {
      loggingOut = false;
      this.savedCallbackContext.success("logged out");
    } else if (result.getErrorCode() == ConnectionResult.SIGN_IN_REQUIRED && !trySilentLogin) {
      final PendingIntent mSignInIntent = result.getResolution();
      try {
        // startIntentSenderForResult is started from the CordovaActivity,
        // set callback to this plugin to make sure this.onActivityResult gets called afterwards
        ((CordovaActivity) this.cordova.getActivity()).setActivityResultCallback(this);
        this.cordova.getActivity().startIntentSenderForResult(mSignInIntent.getIntentSender(), 0, null, 0, 0, 0);
      } catch (IntentSender.SendIntentException ignore) {
        mGoogleApiClient.connect();
      }
    } else {
      this.savedCallbackContext.error("no valid token");
    }
  }

  @Override
  public void onActivityResult(int requestCode, final int resultCode, final Intent intent) {
    super.onActivityResult(requestCode, resultCode, intent);
    if (resultCode == Activity.RESULT_OK) {
      mGoogleApiClient.connect();
    } else {
      this.savedCallbackContext.error("user cancelled");
    }
  }
}
