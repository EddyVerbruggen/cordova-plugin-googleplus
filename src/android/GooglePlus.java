package nl.xservices.plugins;

import android.app.Activity;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.IntentSender;
import android.os.Bundle;
import com.google.android.gms.auth.GoogleAuthException;
import com.google.android.gms.auth.GoogleAuthUtil;
import com.google.android.gms.auth.UserRecoverableAuthException;
import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.GooglePlayServicesUtil;
import com.google.android.gms.common.Scopes;
import com.google.android.gms.common.api.GoogleApiClient;
import com.google.android.gms.common.api.GoogleApiClient.ConnectionCallbacks;
import com.google.android.gms.common.api.GoogleApiClient.OnConnectionFailedListener;
import com.google.android.gms.common.api.ResultCallback;
import com.google.android.gms.common.api.Scope;
import com.google.android.gms.common.api.Status;
import com.google.android.gms.plus.Plus;
import com.google.android.gms.plus.model.people.Person;
import org.apache.cordova.*;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class GooglePlus extends CordovaPlugin implements ConnectionCallbacks, OnConnectionFailedListener {

  public static final String ACTION_IS_AVAILABLE = "isAvailable";
  public static final String ACTION_LOGIN = "login";
  public static final String ACTION_TRY_SILENT_LOGIN = "trySilentLogin";
  public static final String ACTION_LOGOUT = "logout";
  public static final String ACTION_DISCONNECT = "disconnect";
  public static final String ARGUMENT_ANDROID_KEY = "androidApiKey";
  public static final String ARGUMENT_WEB_KEY = "webApiKey";
  public static final String ARGUMENT_SCOPES = "scopes";
  public static final String ARGUMENT_OFFLINE_KEY = "offline";

  /**
   * Email for the google account that is being logged in
   */
  private String email;
  /**
   * JSON of useful information from the result of a successful connection to the google services api
   */
  private JSONObject result;
  /**
   * List of scopes that we'll request from the google services api
   */
  private List<Scope> scopes = new ArrayList<Scope>();

  // Wraps our service connection to Google Play services and provides access to the users sign in state and Google APIs
  private GoogleApiClient mGoogleApiClient;
  private String apiKey, webKey, scopesString;
  private CallbackContext savedCallbackContext;
  private boolean trySilentLogin;
  private boolean loggingOut;
  private boolean requestOfflineToken;

  @Override
  public void initialize(CordovaInterface cordova, CordovaWebView webView) {
    super.initialize(cordova, webView);
  }

  @Override
  public boolean execute(String action, CordovaArgs args, CallbackContext callbackContext) throws JSONException {
    this.savedCallbackContext = callbackContext;

    if (args.optJSONObject(0) != null) {
      JSONObject obj = args.getJSONObject(0);
      this.webKey = obj.optString(ARGUMENT_WEB_KEY, null);
      this.apiKey = obj.optString(ARGUMENT_ANDROID_KEY, null);
      this.requestOfflineToken = obj.optBoolean(ARGUMENT_OFFLINE_KEY, false);
      this.setupScopes(obj.optString(ARGUMENT_SCOPES, null));
      // possible scope change, so force a rebuild of the client
      this.mGoogleApiClient = null;
    }

    //It's important that we build the GoogleApiClient after setting up scopes so we know which scopes to request when setting up the google services api client.
    buildGoogleApiClient();

    if (ACTION_IS_AVAILABLE.equals(action)) {
      final boolean avail = GooglePlayServicesUtil.isGooglePlayServicesAvailable(this.cordova.getActivity().getApplicationContext()) == 0;
      savedCallbackContext.success("" + avail);

    } else if (ACTION_LOGIN.equals(action)) {
      this.trySilentLogin = false;
      mGoogleApiClient.reconnect();

    } else if (ACTION_TRY_SILENT_LOGIN.equals(action)) {
      this.trySilentLogin = true;
      mGoogleApiClient.reconnect();

    } else if (ACTION_LOGOUT.equals(action)) {
      try {
        Plus.AccountApi.clearDefaultAccount(mGoogleApiClient);
        mGoogleApiClient.disconnect();
        // needed in onActivityResult when the connect method below comes back
        loggingOut = true;
        buildGoogleApiClient();
        mGoogleApiClient.connect();
      } catch (IllegalStateException ignore) {
      }
      savedCallbackContext.success("logged out");

    } else if (ACTION_DISCONNECT.equals(action)) {
      disconnect();
    } else {
      return false;
    }
    return true;
  }

  /**
   * Setup scopes that we will request from the google plus api.  Defaults to profile and https://www.googleapis.com/auth/plus.login.
   * See https://developers.google.com/+/web/api/rest/oauth for more info about scopes.
   * @param scopes Space delimited list of scopes
   */
  private void setupScopes(String scopes) {
    if (scopes != null) {
      this.scopesString = scopes;
      for(String scope : scopes.split(" ")) {
        this.scopes.add(new Scope(scope));
      }
    } else {
      this.scopesString = Scopes.PLUS_LOGIN;
      this.scopes.add(Plus.SCOPE_PLUS_LOGIN);
      this.scopes.add(Plus.SCOPE_PLUS_PROFILE);
    }
  }

  private void disconnect() {
    try {
      Plus.AccountApi.revokeAccessAndDisconnect(mGoogleApiClient)
          .setResultCallback(new ResultCallback<Status>() {
            @Override
            public void onResult(Status status) {
              // mGoogleApiClient is now disconnected and access has been revoked.
              // Don't care if it was disconnected already (status != success).
              buildGoogleApiClient();
              savedCallbackContext.success("disconnected");
            }
          });
    } catch (IllegalStateException e) {
      savedCallbackContext.success("disconnected");
    }
  }

  /**
   * Build the GoogleApiClient if it has not already been built.
   *
   * @return Our GoogleApiClient
   */
  private synchronized GoogleApiClient buildGoogleApiClient() {
    if (this.mGoogleApiClient != null) {
      return this.mGoogleApiClient;
    }

    GoogleApiClient.Builder builder = new GoogleApiClient.Builder(webView.getContext())
        .addConnectionCallbacks(this)
        .addOnConnectionFailedListener(this)
        .addApi(Plus.API, Plus.PlusOptions.builder().build());

    for (Scope scope : this.scopes) {
      builder.addScope(scope);
    }

    this.mGoogleApiClient = builder.build();
    return this.mGoogleApiClient;
  }

  private void resolveToken(final String email, final JSONObject result) {
    final Context context = this.cordova.getActivity().getApplicationContext();

    cordova.getThreadPool().execute(new Runnable() {
      public void run() {
        String scope;
        String token;

        try {
          if (GooglePlus.this.webKey != null){
            // Retrieve server side tokens
            scope = "audience:server:client_id:" + GooglePlus.this.webKey;
            token = GoogleAuthUtil.getToken(context, email, scope);
            result.put("idToken", token);
          }

          // if API key or offline flag is set, then also get the OAuth access token
          if (GooglePlus.this.apiKey != null) {
            // Retrieve the oauth token with offline mode
            scope = "oauth2:server:client_id:" + GooglePlus.this.apiKey;
            scope += ":api_scope:" + GooglePlus.this.scopesString;
            token = GoogleAuthUtil.getToken(context, email, scope);
            result.put("oauthToken", token);
          } else if(GooglePlus.this.requestOfflineToken) {
            // Retrieve the oauth token with offline mode
            scope = "oauth2:" + Scopes.PLUS_LOGIN;
            token = GoogleAuthUtil.getToken(context, email, scope);
            result.put("oauthToken", token);
          }
        }
        catch (UserRecoverableAuthException userAuthEx) {
          // Start the user recoverable action using the intent returned by
          // getIntent()
          cordova.setActivityResultCallback(GooglePlus.this);
          cordova.getActivity().startActivityForResult(userAuthEx.getIntent(), /*requestCode*/0);
          return;
        }
        catch (IOException e) {
          savedCallbackContext.error("Failed to retrieve token: " + e.getMessage());
          return;
        } catch (GoogleAuthException e) {
          savedCallbackContext.error("Failed to retrieve token: " + e.getMessage());
          return;
        } catch (JSONException e) {
          savedCallbackContext.error("Failed to retrieve token: " + e.getMessage());
          return;
        }

        savedCallbackContext.success(result);
      }
    });
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
    final Person user = Plus.PeopleApi.getCurrentPerson(mGoogleApiClient);
    this.email = Plus.AccountApi.getAccountName(mGoogleApiClient);
    this.result = new JSONObject();

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
        this.cordova.setActivityResultCallback(this);
        this.cordova.getActivity().startIntentSenderForResult(mSignInIntent.getIntentSender(), 0, null, 0, 0, 0);
      } catch (IntentSender.SendIntentException ignore) {
        mGoogleApiClient.connect();
      }
    } else {
      this.savedCallbackContext.error("no valid token");
    }
  }

  /**
   * Handle the user's action from the permissioning workflow.  In this workflow a user may be asked for access to his profile, email, offline access etc.
   *
   * There are three situations we cover:
   *
   * 1. The user clicks sign in. We are not yet connected to the google services api. (common case)
   *
   * 2. The user clicks sign in and we are already connected to the google services api.  This case is less common, and it's a bit confusing
   * why we'd already be connected to the google services api before the user clicks sign in.  This case happens when the user sees multiple pages
   * in the permission workflow.  The user will see multiple pages in the workflow when we connect to the google services api (successfully), but on
   * connection google tells us that we should prompt the user for even more permissions that the first page of the workflow didn't ask for via
   * a UserRecoverableAuthException.  For example, a user may first be prompted for basic profile access.  Then when we connect to the google services api
   * it may suggest that we also need to prompt the user for offline access.  In this case we don't bother reconnecting to the google services api again.  Instead,
   * we skip straight to resolving to the token.
   *
   * 3. The user clicks cancel.
   *
   * @param requestCode The request code originally supplied to startActivityForResult(),
   * @param resultCode The integer result code returned by the child activity through its setResult().
   * @param intent Information returned by the child activity
   */
  @Override
  public void onActivityResult(int requestCode, final int resultCode, final Intent intent) {
    super.onActivityResult(requestCode, resultCode, intent);
    if (!mGoogleApiClient.isConnected() && resultCode == Activity.RESULT_OK) {
      mGoogleApiClient.connect();
    } else if (resultCode == Activity.RESULT_OK) {
      this.resolveToken(email, result);
    } else {
      this.savedCallbackContext.error("user cancelled");
    }
  }
}
