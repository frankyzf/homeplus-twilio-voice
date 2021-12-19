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
import com.tradingvision.homeplus.RNTwilioVoice.VoiceActivity;

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
    private static VoiceActivity voiceInstance;
    private String myAccessToken;

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

    public static void SetVoiceInstance(VoiceActivity p) {
        voiceInstance = p;
        Log.i(TAG, "voice instance is set");
    }

    @ReactMethod
    public void initWithAccessToken(final String accessToken, Promise promise) {
        if (accessToken.equals("")) {
            Log.e(TAG, "access token is empty, return directly");
            promise.reject(new JSApplicationIllegalArgumentException("Invalid access token"));
            return;
        }
        TwilioVoiceModule.this.myAccessToken = accessToken;
        if (BuildConfig.DEBUG) {
            Log.d(TAG, "initWithAccessToken():" + TwilioVoiceModule.this.myAccessToken);
        }

        try {
            Activity currentActivity = getCurrentActivity();
            if (null != currentActivity) {
                Class toActivity = Class.forName("com.tradingvision.homeplus.RNTwilioVoice.VoiceActivity");
                Intent intent = new Intent(currentActivity, toActivity);
                // intent.putExtra("params", params);
                currentActivity.startActivity(intent);
				        promise.resolve(true);
            }
        } catch (Exception e) {
            promise.reject( new JSApplicationIllegalArgumentException(
                    "can not open activity : " + e.getMessage()));
        }
    }

    @ReactMethod
    public void configureCallKit(ReadableMap params, Promise promise) {
        if (BuildConfig.DEBUG) {
            Log.d(TAG, "configureCallKit(). Params: " + params);
        }
		String name = params.getString("name");
        if (TwilioVoiceModule.voiceInstance == null) {
            Log.e(TAG, "voice instance is null");
			promise.reject(new JSApplicationIllegalArgumentException("voice instance is null"));
        } else {
            TwilioVoiceModule.voiceInstance.accessToken = this.myAccessToken;
            TwilioVoiceModule.voiceInstance.registerForCallInvites();
			promise.resolve(true);
        }

    }

}