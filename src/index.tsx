import { NativeModules, Platform } from 'react-native';

// const ANDROID = "android";
const IOS = "ios";

const LINKING_ERROR =
  `The package 'homeplus-twilio-voice' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo managed workflow\n';

const RNTwilioVoice = NativeModules.RNTwilioVoice
  ? NativeModules.RNTwilioVoice
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

const Twilio = {
  // initialize the library with Twilio access token
  // return {initialized: true} when the initialization started
  // Listen to deviceReady and deviceNotReady events to see whether
  // the initialization succeeded
  async initWithToken(token:string) {
    if (typeof token !== "string") {
      return {
        initialized: false,
        err: "Invalid token, token must be a string",
      };
    }
    const result = await RNTwilioVoice.initWithAccessToken(token);
    // native react promise present only for Android
    // iOS initWithAccessToken doesn't return
    if (Platform.OS === IOS) {
      return {
        initialized: true,
      };
    }
    return result;
  },
  configureCallKit(params = {}) {
    RNTwilioVoice.configureCallKit(params);
  }
};
export default Twilio;

