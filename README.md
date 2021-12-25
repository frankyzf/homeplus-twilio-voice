# homeplus-twilio-voice

This is a wrapper for the integration react native app with twilio voice service.

## Installation

```sh
npm install homeplus-twilio-voice
```

## Usage

```js
import TwilioVoice from 'homeplus-twilio-voice';

// ...
// access token is got from somewhere or pre-assigned
TwilioVoice.initWithToken(access_token);
TwilioVoice.configureCallKit({
  appName: 'HomePlus',
});
```

### android integration

android use google sms service to receive notification, so to configure it before enjoy the service.

#### in the project build.gradle file

```
buildscript {
  //other info ...
  dependencies {
    //add google-service
    classpath 'com.google.gms:google-services:4.3.4'
  }
}


apply plugin: 'com.google.gms.google-services'

```

### change the app/src/main/AndroidManifest.xml

```xml
<manifest>
  <uses-permission android:name="android.permission.INTERNET" />
  <uses-permission android:name="android.permission.CAMERA" />
  <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
  <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
  <uses-permission android:name="android.permission.RECORD_AUDIO" />
  <application>
  <!-- Twilio Voice -->
        <!-- [START fcm_listener] -->
      <service
            android:name="com.tradingvision.homeplus.RNTwilioVoice.fcm.VoiceFirebaseMessagingService"
            android:exported="true"
            android:stopWithTask="false">
            <intent-filter>
                <action android:name="com.google.firebase.MESSAGING_EVENT" />
            </intent-filter>
        </service>
        <service
            android:enabled="true"
            android:exported="true"
            android:name="com.tradingvision.homeplus.RNTwilioVoice.IncomingCallNotificationService"
            android:foregroundServiceType="phoneCall">
            <intent-filter>
                <action android:name="com.tradingvision.homeplus.RNTwilioVoice.ACTION_ACCEPT" />
                <action android:name="com.tradingvision.homeplus.RNTwilioVoice.ACTION_REJECT" />
            </intent-filter>
        </service>
        <!-- [END fcm_listener] -->
        <!-- Twilio Voice -->
  </application>



</manifest>

```

### change the app/build.gradle

```
apply plugin: 'com.google.gms.google-services'
android {
  // nothing change needed
}
dependencies {
  implementation platform('com.google.firebase:firebase-bom:26.0.0')
    implementation "com.google.firebase:firebase-messaging"

    implementation "com.twilio:audioswitch:1.1.3"
    implementation 'com.twilio:voice-android:6.0.2'

    implementation "androidx.lifecycle:lifecycle-extensions:2.2.0"
    implementation "com.google.android.material:material:1.4.0"
    implementation project(':react-native-gesture-handler')
    implementation 'com.squareup.okhttp3:okhttp:4.9.0'
}

```

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT
