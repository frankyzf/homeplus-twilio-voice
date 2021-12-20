package com.tradingvision.homeplus.RNTwilioVoice;

import static android.content.pm.PackageManager.PERMISSION_GRANTED;

import android.Manifest;
import android.app.Activity;
import android.app.AlertDialog;
import android.app.NotificationManager;
import android.app.ActivityManager.RunningAppProcessInfo;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.content.res.ColorStateList;
import android.media.AudioManager;
import android.os.Build;
import android.os.Build.VERSION_CODES;
import android.os.Bundle;
import android.os.SystemClock;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.widget.Chronometer;
import android.widget.EditText;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import androidx.appcompat.app.AppCompatActivity;
import androidx.coordinatorlayout.widget.CoordinatorLayout;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.lifecycle.Lifecycle;
import androidx.lifecycle.ProcessLifecycleOwner;
import androidx.localbroadcastmanager.content.LocalBroadcastManager;
import kotlin.Unit;

import android.os.Bundle;
import android.util.Log;
import android.content.ServiceConnection;
import android.os.Binder;
import android.os.IBinder;
import android.content.ComponentName;


import com.facebook.react.ReactApplication;
import com.facebook.react.ReactInstanceManager;

import com.facebook.react.bridge.JSApplicationIllegalArgumentException;
import com.facebook.react.bridge.AssertionException;
import com.facebook.react.bridge.LifecycleEventListener;
import com.facebook.react.bridge.ReadableMap;

import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReadableMapKeySetIterator;
import com.facebook.react.bridge.ReadableType;
import com.facebook.react.bridge.WritableMap;

import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

import com.google.android.material.floatingactionbutton.FloatingActionButton;
import com.google.android.material.snackbar.Snackbar;
import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.Task;
import com.google.firebase.iid.FirebaseInstanceId;
import com.google.firebase.iid.InstanceIdResult;

import com.twilio.audioswitch.AudioDevice;
import com.twilio.audioswitch.AudioSwitch;
import com.twilio.voice.AcceptOptions;
import com.twilio.voice.Call;
import com.twilio.voice.CallException;
import com.twilio.voice.CallInvite;
import com.twilio.voice.CancelledCallInvite;
import com.twilio.voice.ConnectOptions;
import com.twilio.voice.LogLevel;
import com.twilio.voice.RegistrationException;
import com.twilio.voice.RegistrationListener;
import com.twilio.voice.UnregistrationListener;
import com.twilio.voice.Voice;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.Map;

import kotlin.Unit;
import com.tradingvision.homeplus.RNTwilioVoice.IncomingCallNotificationService;

import static com.tradingvision.homeplus.RNTwilioVoice.CallNotificationManager.getMainActivityClass;
import static com.tradingvision.homeplus.RNTwilioVoice.EventManager.EVENT_CONNECTION_DID_CONNECT;
import static com.tradingvision.homeplus.RNTwilioVoice.EventManager.EVENT_CONNECTION_DID_DISCONNECT;
import static com.tradingvision.homeplus.RNTwilioVoice.EventManager.EVENT_DEVICE_DID_RECEIVE_INCOMING;
import static com.tradingvision.homeplus.RNTwilioVoice.EventManager.EVENT_DEVICE_NOT_READY;
import static com.tradingvision.homeplus.RNTwilioVoice.EventManager.EVENT_DEVICE_READY;
import static com.tradingvision.homeplus.RNTwilioVoice.EventManager.EVENT_CALL_STATE_RINGING;
import static com.tradingvision.homeplus.RNTwilioVoice.EventManager.EVENT_CALL_INVITE_CANCELLED;
import static com.tradingvision.homeplus.RNTwilioVoice.EventManager.EVENT_CONNECTION_IS_RECONNECTING;
import static com.tradingvision.homeplus.RNTwilioVoice.EventManager.EVENT_CONNECTION_DID_RECONNECT;
import static com.tradingvision.homeplus.RNTwilioVoice.EventManager.EVENT_AUDIO_DEVICES_UPDATED;

import com.facebook.react.module.annotations.ReactModule;

@ReactModule(name = "RNTwilioVoice")

public class TwilioVoiceModule extends ReactContextBaseJavaModule {

  public static String TAG = "RNTwilioVoice";
  private String myAccessToken = "";




  public TwilioVoiceModule(ReactApplicationContext reactContext) {
      super(reactContext);
      if (BuildConfig.DEBUG) {
          Voice.setLogLevel(LogLevel.DEBUG);
      } else {
          Voice.setLogLevel(LogLevel.ERROR);
      }
  }

  @Override
  @NonNull
  public String getName() {
      return TAG;
  }

  @ReactMethod
  public void initWithAccessToken(final String accessToken, Promise promise) {
      Log.i(TAG, "initWithAccessToken:" + accessToken);
      if (accessToken.equals("")) {
          Log.e(TAG, "access token is empty, return directly");
          promise.reject(new JSApplicationIllegalArgumentException("Invalid access token"));
          return;
      }
      TwilioVoiceModule.this.myAccessToken = accessToken;
      if (BuildConfig.DEBUG) {
          Log.d(TAG, "initWithAccessToken():" + TwilioVoiceModule.this.myAccessToken);
      }
      promise.resolve(null);
  }

  @ReactMethod
  public void configureCallKit(ReadableMap params) {
    if (BuildConfig.DEBUG) {
        Log.d(TAG, "configureCallKit(). Params: " + params);
    }
    String name = params.getString("name");
    Log.i(TAG, "voice instance begin to register for call with name:" + name + " token:" + this.myAccessToken);
    this.registerForCallInvites(this.myAccessToken);
  }

  /*
   * Register your FCM token with Twilio to receive incoming call invites
   */
  public void registerForCallInvites(String accessToken) {
    Log.i(TAG, "begin to Registering for call invite with accessToken:" + accessToken);
    Activity currentActivity = getCurrentActivity();
    Intent intent = new Intent(currentActivity, getMainActivityClass(this.getReactApplicationContext()));
    intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP);
    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
    intent.setAction(Constants.ACTION_FCM_TOKEN);
    intent.putExtra(Constants.ACCESS_TOKEN, accessToken);
    currentActivity.startActivity(intent);
  }

  public static Bundle getActivityLaunchOption(Intent intent) {
      Bundle initialProperties = new Bundle();
      if (intent == null || intent.getAction() == null) {
          Log.e(TAG, "intent is null or intent action is null");
          return initialProperties;
      }

      Bundle callBundle = new Bundle();
      Log.i(TAG, "getActivityLaunchOption action is " + intent.getAction());
      switch (intent.getAction()) {
          case Constants.ACTION_INCOMING_CALL_NOTIFICATION:
              callBundle.putString(Constants.CALL_SID, intent.getStringExtra(Constants.CALL_SID));
              callBundle.putString(Constants.CALL_FROM, intent.getStringExtra(Constants.CALL_FROM));
              callBundle.putString(Constants.CALL_TO, intent.getStringExtra(Constants.CALL_TO));
              initialProperties.putBundle(Constants.CALL_INVITE_KEY, callBundle);
              break;

          case Constants.ACTION_ACCEPT:
              callBundle.putString(Constants.CALL_SID, intent.getStringExtra(Constants.CALL_SID));
              callBundle.putString(Constants.CALL_FROM, intent.getStringExtra(Constants.CALL_FROM));
              callBundle.putString(Constants.CALL_TO, intent.getStringExtra(Constants.CALL_TO));
              callBundle.putString(Constants.CALL_STATE, Constants.CALL_STATE_CONNECTED);
              initialProperties.putBundle(Constants.CALL_KEY, callBundle);
              break;
      }
      return initialProperties;
  }

}
