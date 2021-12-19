package com.tradingvision.homeplus.RNTwilioVoice;

import androidx.annotation.Nullable;
import android.util.Log;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import static com.tradingvision.homeplus.RNTwilioVoice.TwilioVoiceModule.TAG;

public class EventManager {

    private ReactApplicationContext mContext;

    public static final String EVENT_PROXIMITY = "proximity";
    public static final String EVENT_WIRED_HEADSET = "wiredHeadset";

    public static final String EVENT_DEVICE_READY = "deviceReady";
    public static final String EVENT_DEVICE_NOT_READY = "deviceNotReady";
    public static final String EVENT_CONNECTION_DID_CONNECT = "connectionDidConnect";
    public static final String EVENT_CONNECTION_DID_DISCONNECT = "connectionDidDisconnect";
    public static final String EVENT_DEVICE_DID_RECEIVE_INCOMING = "deviceDidReceiveIncoming";
    public static final String EVENT_CALL_STATE_RINGING = "callStateRinging";
    public static final String EVENT_CALL_INVITE_CANCELLED = "callInviteCancelled";
    public static final String EVENT_CONNECTION_IS_RECONNECTING = "connectionIsReconnecting";
    public static final String EVENT_CONNECTION_DID_RECONNECT = "connectionDidReconnect";
    public static final String EVENT_AUDIO_DEVICES_UPDATED = "audioDevicesUpdated";

    public EventManager(ReactApplicationContext context) {
        mContext = context;
    }

    public void sendEvent(String eventName, @Nullable WritableMap params) {
        Log.i(TAG, "sendEvent " + eventName + " params " + params);

        // == comment on purpose, here just handle the sdk directly
        // if (mContext.hasActiveCatalystInstance()) {
        // mContext
        // .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
        // .emit(eventName, params);
        // } else {
        // if (BuildConfig.DEBUG) {
        // Log.d(TAG, "failed Catalyst instance not active");
        // }
        // }
    }
}
