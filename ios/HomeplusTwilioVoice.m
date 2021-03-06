#import "HomeplusTwilioVoice.h"
// #import "ViewController.h"
#import <React/RCTLog.h>


@import AVFoundation;
@import PushKit;
@import CallKit;
@import TwilioVoice;

// static NSString *const kAccessToken = PASTE YOUR ACCESS TOKEN HERE;
static NSString *const kTwimlParamTo = @"to";

static NSInteger const kRegistrationTTLInDays = 365;

NSString * const kCachedDeviceToken = @"CachedDeviceToken";
NSString * const kCachedBindingTime = @"CachedBindingTime";

@interface ViewController () <TVONotificationDelegate, TVOCallDelegate, CXProviderDelegate, UITextFieldDelegate, AVAudioPlayerDelegate>

@property (nonatomic, strong) void(^incomingPushCompletionCallback)(void);
@property (nonatomic, strong) void(^callKitCompletionCallback)(BOOL);
@property (nonatomic, strong) TVODefaultAudioDevice *audioDevice;
@property (nonatomic, strong) NSMutableDictionary *activeCallInvites;
@property (nonatomic, strong) NSMutableDictionary *activeCalls;

// activeCall represents the last connected call
@property (nonatomic, strong) TVOCall *activeCall;

@property (nonatomic, strong) CXProvider *callKitProvider;
@property (nonatomic, strong) CXCallController *callKitCallController;
@property (nonatomic, assign) BOOL userInitiatedDisconnect;

@property (weak, nonatomic) IBOutlet UILabel *qualityWarningsToaster;
@property (nonatomic, weak) IBOutlet UIImageView *iconView;
@property (nonatomic, assign, getter=isSpinning) BOOL spinning;

@property (nonatomic, weak) IBOutlet UIButton *placeCallButton;
@property (nonatomic, weak) IBOutlet UITextField *outgoingValue;
@property (weak, nonatomic) IBOutlet UIView *callControlView;
@property (weak, nonatomic) IBOutlet UISwitch *muteSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *speakerSwitch;

@property (nonatomic, assign) BOOL playCustomRingback;
@property (nonatomic, strong) AVAudioPlayer *ringtonePlayer;

@property NSString *kAccessToken;

@end

// @import AVFoundation;
// @import PushKit;
// @import CallKit;
@import TwilioVoice;

// @interface RNTwilioVoice () <PKPushRegistryDelegate, TVONotificationDelegate, TVOCallDelegate, CXProviderDelegate>
@interface RNTwilioVoice () <PKPushRegistryDelegate>

  @property (nonatomic, weak) id<PushKitEventDelegate> pushKitEventDelegate;
  @property (nonatomic, strong) PKPushRegistry *voipRegistry;
  @property ViewController* controller;
  @property NSString * token;

// @property (nonatomic, strong) void(^incomingPushCompletionCallback)(void);
// @property (nonatomic, strong) void(^callKitCompletionCallback)(BOOL);
// @property (nonatomic, strong) TVODefaultAudioDevice *audioDevice;
// @property (nonatomic, strong) NSMutableDictionary *activeCallInvites;
// @property (nonatomic, strong) NSMutableDictionary *activeCalls;


// // activeCall represents the last connected call
// @property (nonatomic, strong) TVOCall *activeCall;
// @property (nonatomic, strong) CXProvider *callKitProvider;
// @property (nonatomic, strong) CXCallController *callKitCallController;
// @property (nonatomic, assign) BOOL userInitiatedDisconnect;

@end

@implementation RNTwilioVoice {
  // NSMutableDictionary *_settings;
  // NSMutableDictionary *_callParams;
  // NSString *_tokenUrl;
}

NSString * const StateConnecting = @"CONNECTING";
NSString * const StateConnected = @"CONNECTED";
NSString * const StateDisconnected = @"DISCONNECTED";
NSString * const StateRejected = @"REJECTED";

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE()

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"connectionDidConnect", @"connectionDidDisconnect", @"callRejected", @"deviceReady", @"deviceNotReady", @"deviceDidReceiveIncoming", @"callInviteCancelled", @"callStateRinging", @"connectionIsReconnecting", @"connectionDidReconnect"];
}

@synthesize bridge = _bridge;

- (void)dealloc {
  // if (self.callKitProvider) {
  //   [self.callKitProvider invalidate];
  // }

  // [[NSNotificationCenter defaultCenter] removeObserver:self];
}

RCT_EXPORT_METHOD(initWithAccessToken:(NSString *)token) {
    self.token = token;
    NSLog(@"Twilio Voice Version: %@", [TwilioVoice sdkVersion]);
    NSLog(@"Twilio Voice access token: %@", self.token);

//    ViewController* viewController = (ViewController*)self.window.rootViewController;
    ViewController* viewController = [[ViewController alloc] initWithToken:token];
    self.pushKitEventDelegate = viewController;
    self.controller = viewController;
    /*
     * Your app must initialize PKPushRegistry with PushKit push type VoIP at the launch time. As mentioned in the
     * [PushKit guidelines](https://developer.apple.com/documentation/pushkit/supporting_pushkit_notifications_in_your_app),
     * the system can't deliver push notifications to your app until you create a PKPushRegistry object for
     * VoIP push type and set the delegate. If your app delays the initialization of PKPushRegistry, your app may receive outdated
     * PushKit push notifications, and if your app decides not to report the received outdated push notifications to CallKit, iOS may
     * terminate your app.
     */
    [self initializePushKit];
  // [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAppTerminateNotification) name:UIApplicationWillTerminateNotification object:nil];
  // [self initPushRegistry];
}

- (void)initializePushKit {
    self.voipRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
    self.voipRegistry.delegate = self;
    self.voipRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
}


RCT_EXPORT_METHOD(configureCallKit: (NSDictionary *)params) {
  NSLog(@"CallKit Initialized");
  [self.controller configureCallKit: params];
}

// RCT_EXPORT_METHOD(configureCallKit: (NSDictionary *)params) {
//   if (self.callKitCallController == nil) {
//       /*
//        * The important thing to remember when providing a TVOAudioDevice is that the device must be set
//        * before performing any other actions with the SDK (such as connecting a Call, or accepting an incoming Call).
//        * In this case we've already initialized our own `TVODefaultAudioDevice` instance which we will now set.
//        */
//       self.audioDevice = [TVODefaultAudioDevice audioDevice];
//       TwilioVoice.audioDevice = self.audioDevice;

//       self.activeCallInvites = [NSMutableDictionary dictionary];
//       self.activeCalls = [NSMutableDictionary dictionary];

//     _settings = [[NSMutableDictionary alloc] initWithDictionary:params];
//     CXProviderConfiguration *configuration = [[CXProviderConfiguration alloc] initWithLocalizedName:params[@"appName"]];
//     configuration.maximumCallGroups = 1;
//     configuration.maximumCallsPerCallGroup = 1;
//     if (_settings[@"imageName"]) {
//       configuration.iconTemplateImageData = UIImagePNGRepresentation([UIImage imageNamed:_settings[@"imageName"]]);
//     }
//     if (_settings[@"ringtoneSound"]) {
//       configuration.ringtoneSound = _settings[@"ringtoneSound"];
//     }

//     _callKitProvider = [[CXProvider alloc] initWithConfiguration:configuration];
//     [_callKitProvider setDelegate:self queue:nil];

//     NSLog(@"CallKit Initialized");

//     self.callKitCallController = [[CXCallController alloc] init];
//   }
// }


- (NSString *)fetchAccessToken {
  NSLog(@"fetchAccessToken:%@", self.token);
  return _token;
}

#pragma mark - PKPushRegistryDelegate
- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(NSString *)type {
    NSLog(@"pushRegistry:didUpdatePushCredentials:forType:");

    if ([type isEqualToString:PKPushTypeVoIP]) {
        [self.controller setAccess: self.token];
        if (self.pushKitEventDelegate && [self.pushKitEventDelegate respondsToSelector:@selector(credentialsUpdated:)]) {
            [self.pushKitEventDelegate credentialsUpdated:credentials];
        }
    }
}

- (void)pushRegistry:(PKPushRegistry *)registry didInvalidatePushTokenForType:(PKPushType)type {
    NSLog(@"pushRegistry:didInvalidatePushTokenForType:");

    if ([type isEqualToString:PKPushTypeVoIP]) {
        [self.controller setAccess: self.token];
        if (self.pushKitEventDelegate && [self.pushKitEventDelegate respondsToSelector:@selector(credentialsInvalidated)]) {
            [self.pushKitEventDelegate credentialsInvalidated];
        }
    }
}

- (void)pushRegistry:(PKPushRegistry *)registry
didReceiveIncomingPushWithPayload:(PKPushPayload *)payload
             forType:(NSString *)type {
    NSLog(@"pushRegistry:didReceiveIncomingPushWithPayload:forType:");

    [self.controller setAccess: self.token];
    if (self.pushKitEventDelegate &&
        [self.pushKitEventDelegate respondsToSelector:@selector(incomingPushReceived:withCompletionHandler:)]) {
        [self.pushKitEventDelegate incomingPushReceived:payload withCompletionHandler:nil];
    }
}

/**
 * This delegate method is available on iOS 11 and above. Call the completion handler once the
 * notification payload is passed to the `TwilioVoiceSDK.handleNotification()` method.
 */
- (void)pushRegistry:(PKPushRegistry *)registry
didReceiveIncomingPushWithPayload:(PKPushPayload *)payload
             forType:(PKPushType)type
withCompletionHandler:(void (^)(void))completion {
    NSLog(@"pushRegistry:didReceiveIncomingPushWithPayload:forType:withCompletionHandler:");

    [self.controller setAccess:self.token];
    if (self.pushKitEventDelegate &&
        [self.pushKitEventDelegate respondsToSelector:@selector(incomingPushReceived:withCompletionHandler:)]) {
        [self.pushKitEventDelegate incomingPushReceived:payload withCompletionHandler:completion];
    }

    if ([[NSProcessInfo processInfo] operatingSystemVersion].majorVersion >= 13) {
        /*
         * The Voice SDK processes the call notification and returns the call invite synchronously. Report the incoming call to
         * CallKit and fulfill the completion before exiting this callback method.
         */
        completion();
    }
}

// RCT_EXPORT_METHOD(connect: (NSDictionary *)params) {
//   NSLog(@"Calling phone number %@", [params valueForKey:@"To"]);

//   UIDevice* device = [UIDevice currentDevice];
//   device.proximityMonitoringEnabled = YES;

//   if (self.activeCall && self.activeCall.state == TVOCallStateConnected) {
//     [self performEndCallActionWithUUID:self.activeCall.uuid];
//   } else {
//     NSUUID *uuid = [NSUUID UUID];
//     NSString *handle = [params valueForKey:@"To"];
//     _callParams = [[NSMutableDictionary alloc] initWithDictionary:params];
//     [self performStartCallActionWithUUID:uuid handle:handle];
//   }
// }

// RCT_EXPORT_METHOD(disconnect) {
//     NSLog(@"Disconnecting call. UUID %@", self.activeCall.uuid.UUIDString);
//     self.userInitiatedDisconnect = YES;
//     [self performEndCallActionWithUUID:self.activeCall.uuid];
// }

// RCT_EXPORT_METHOD(setMuted: (BOOL *)muted) {
//   NSLog(@"Mute/UnMute call");
//     self.activeCall.muted = muted ? YES : NO;
// }

// RCT_EXPORT_METHOD(setOnHold: (BOOL *)isOnHold) {
//   NSLog(@"Hold/Unhold call");
//     self.activeCall.onHold = isOnHold ? YES : NO;
// }

// RCT_EXPORT_METHOD(setSpeakerPhone: (BOOL *)speaker) {
//     [self toggleAudioRoute: speaker ? YES : NO];
// }

// RCT_EXPORT_METHOD(sendDigits: (NSString *)digits) {
//   if (self.activeCall && self.activeCall.state == TVOCallStateConnected) {
//     NSLog(@"SendDigits %@", digits);
//     [self.activeCall sendDigits:digits];
//   }
// }

// RCT_EXPORT_METHOD(unregister) {
//   NSLog(@"unregister");
//   NSString *accessToken = [self fetchAccessToken];
//   NSString *cachedDeviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:kCachedDeviceToken];
//   if ([cachedDeviceToken length] > 0) {
//       [TwilioVoice unregisterWithAccessToken:accessToken
//                                  deviceToken:cachedDeviceToken
//                                   completion:^(NSError * _Nullable error) {
//                                     if (error) {
//                                         NSLog(@"An error occurred while unregistering: %@", [error localizedDescription]);
//                                     } else {
//                                         [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:kCachedDeviceToken];
//                                         NSLog(@"Successfully unregistered for VoIP push notifications.");
//                                     }
//                                 }];
//   }
// }

// RCT_REMAP_METHOD(getActiveCall,
//                  activeCallResolver:(RCTPromiseResolveBlock)resolve
//                  activeCallRejecter:(RCTPromiseRejectBlock)reject) {
//     NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
//     if (self.activeCall) {
//         if (self.activeCall.sid) {
//             [params setObject:self.activeCall.sid forKey:@"call_sid"];
//         }
//         if (self.activeCall.to) {
//             [params setObject:self.activeCall.to forKey:@"call_to"];
//         }
//         if (self.activeCall.from) {
//             [params setObject:self.activeCall.from forKey:@"call_from"];
//         }
//         if (self.activeCall.state == TVOCallStateConnected) {
//             [params setObject:StateConnected forKey:@"call_state"];
//         } else if (self.activeCall.state == TVOCallStateConnecting) {
//             [params setObject:StateConnecting forKey:@"call_state"];
//         } else if (self.activeCall.state == TVOCallStateDisconnected) {
//             [params setObject:StateDisconnected forKey:@"call_state"];
//         }
//     }
//     resolve(params);
// }

// RCT_REMAP_METHOD(getCallInvite,
//                  callInvieteResolver:(RCTPromiseResolveBlock)resolve
//                  callInviteRejecter:(RCTPromiseRejectBlock)reject) {
//     NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
//     if (self.activeCallInvites.count) {
//         // considering only the first call invite
//         TVOCallInvite *callInvite = [self.activeCallInvites valueForKey:[self.activeCallInvites allKeys][self.activeCallInvites.count-1]];
//         if (callInvite.callSid) {
//             [params setObject:callInvite.callSid forKey:@"call_sid"];
//         }
//         if (callInvite.from) {
//             [params setObject:callInvite.from forKey:@"call_from"];
//         }
//         if (callInvite.to) {
//             [params setObject:callInvite.to forKey:@"call_to"];
//         }
//     }
//     resolve(params);
// }

// - (void)initPushRegistry {
//   self.voipRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
//   self.voipRegistry.delegate = self;
//   self.voipRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
// }

// - (NSString *)fetchAccessToken {
//   if (_tokenUrl) {
//     NSString *accessToken = [NSString stringWithContentsOfURL:[NSURL URLWithString:_tokenUrl]
//                                                      encoding:NSUTF8StringEncoding
//                                                         error:nil];
//     return accessToken;
//   } else {
//     return _token;
//   }
// }


// #pragma mark - PKPushRegistryDelegate
// - (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(NSString *)type {
//   NSLog(@"pushRegistry:didUpdatePushCredentials:forType");

//   if ([type isEqualToString:PKPushTypeVoIP]) {
//     const unsigned *tokenBytes = [credentials.token bytes];
//     NSString *deviceTokenString = [NSString stringWithFormat:@"<%08x %08x %08x %08x %08x %08x %08x %08x>",
//                                                         ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
//                                                         ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
//                                                         ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];
//     NSString *accessToken = [self fetchAccessToken];
//     NSString *cachedDeviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:kCachedDeviceToken];
//     if (![cachedDeviceToken isEqualToString:deviceTokenString]) {
//         cachedDeviceToken = deviceTokenString;

//         /*
//          * Perform registration if a new device token is detected.
//          */
//         [TwilioVoice registerWithAccessToken:accessToken
//                                  deviceToken:cachedDeviceToken
//                                   completion:^(NSError *error) {
//              if (error) {
//                  NSLog(@"An error occurred while registering: %@", [error localizedDescription]);
//                  NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
//                  [params setObject:[error localizedDescription] forKey:@"err"];

//                  [self sendEventWithName:@"deviceNotReady" body:params];
//              }
//              else {
//                  NSLog(@"Successfully registered for VoIP push notifications.");

//                  /*
//                   * Save the device token after successfully registered.
//                   */
//                  [[NSUserDefaults standardUserDefaults] setObject:cachedDeviceToken forKey:kCachedDeviceToken];
//                  [self sendEventWithName:@"deviceReady" body:nil];
//              }
//          }];
//     }
//   }
// }



// - (void)pushRegistry:(PKPushRegistry *)registry didInvalidatePushTokenForType:(PKPushType)type {
//   NSLog(@"pushRegistry:didInvalidatePushTokenForType");

//   if ([type isEqualToString:PKPushTypeVoIP]) {
//     NSString *accessToken = [self fetchAccessToken];

//     NSString *cachedDeviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:kCachedDeviceToken];
//     if ([cachedDeviceToken length] > 0) {
//         [TwilioVoice unregisterWithAccessToken:accessToken
//                                                 deviceToken:cachedDeviceToken
//                                                  completion:^(NSError * _Nullable error) {
//                                                    if (error) {
//                                                      NSLog(@"An error occurred while unregistering: %@", [error localizedDescription]);
//                                                    } else {
//                                                      [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:kCachedDeviceToken];
//                                                      NSLog(@"Successfully unregistered for VoIP push notifications.");
//                                                    }
//                                                  }];
//     }
//   }
// }

// /**
// * Try using the `pushRegistry:didReceiveIncomingPushWithPayload:forType:withCompletionHandler:` method if
// * your application is targeting iOS 11. According to the docs, this delegate method is deprecated by Apple.
// */
// - (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type {
//   NSLog(@"pushRegistry:didReceiveIncomingPushWithPayload:forType");
//   if ([type isEqualToString:PKPushTypeVoIP]) {
//       // The Voice SDK will use main queue to invoke `cancelledCallInviteReceived:error` when delegate queue is not passed
//       if (![TwilioVoice handleNotification:payload.dictionaryPayload delegate:self delegateQueue: nil]) {
//           NSLog(@"This is not a valid Twilio Voice notification.");
//       }
//   }
// }

// /**
//  * This delegate method is available on iOS 11 and above. Call the completion handler once the
//  * notification payload is passed to the `TwilioVoice.handleNotification()` method.
//  */
// - (void)pushRegistry:(PKPushRegistry *)registry
// didReceiveIncomingPushWithPayload:(PKPushPayload *)payload
//              forType:(PKPushType)type
// withCompletionHandler:(void (^)(void))completion {
//     NSLog(@"pushRegistry:didReceiveIncomingPushWithPayload:forType:withCompletionHandler");

//     // Save for later when the notification is properly handled.
//     self.incomingPushCompletionCallback = completion;


//     if ([type isEqualToString:PKPushTypeVoIP]) {
//         // The Voice SDK will use main queue to invoke `cancelledCallInviteReceived:error` when delegate queue is not passed
//         if (![TwilioVoice handleNotification:payload.dictionaryPayload delegate:self delegateQueue: nil]) {
//             NSLog(@"This is not a valid Twilio Voice notification.");
//         }
//     }
//     if ([[NSProcessInfo processInfo] operatingSystemVersion].majorVersion < 13) {
//         // Save for later when the notification is properly handled.
//         self.incomingPushCompletionCallback = completion;
//     } else {
//         /**
//         * The Voice SDK processes the call notification and returns the call invite synchronously. Report the incoming call to
//         * CallKit and fulfill the completion before exiting this callback method.
//         */
//         completion();
//     }
// }

// - (void)incomingPushHandled {
//     if (self.incomingPushCompletionCallback) {
//         self.incomingPushCompletionCallback();
//         self.incomingPushCompletionCallback = nil;
//     }
// }

// #pragma mark - TVONotificationDelegate
// - (void)callInviteReceived:(TVOCallInvite *)callInvite {
//     /**
//      * Calling `[TwilioVoice handleNotification:delegate:]` will synchronously process your notification payload and
//      * provide you a `TVOCallInvite` object. Report the incoming call to CallKit upon receiving this callback.
//      */
//     NSLog(@"callInviteReceived");
//     NSString *from = @"Unknown";
//     if (callInvite.from) {
//         from = [callInvite.from stringByReplacingOccurrencesOfString:@"client:" withString:@""];
//     }
//     if (callInvite.customParameters[kCallerNameCustomParameter]) {
//         from = callInvite.customParameters[kCallerNameCustomParameter];
//     }
//     // Always report to CallKit
//     [self reportIncomingCallFrom:from withUUID:callInvite.uuid];
//     self.activeCallInvites[[callInvite.uuid UUIDString]] = callInvite;
//     if ([[NSProcessInfo processInfo] operatingSystemVersion].majorVersion < 13) {
//         [self incomingPushHandled];
//     }

//     NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
//     if (callInvite.callSid) {
//       [params setObject:callInvite.callSid forKey:@"call_sid"];
//     }
//     if (callInvite.from) {
//       [params setObject:callInvite.from forKey:@"call_from"];
//     }
//     if (callInvite.to) {
//       [params setObject:callInvite.to forKey:@"call_to"];
//     }
//     [self sendEventWithName:@"deviceDidReceiveIncoming" body:params];
// }

// - (void)cancelledCallInviteReceived:(nonnull TVOCancelledCallInvite *)cancelledCallInvite {
//     /**
//     * The SDK may call `[TVONotificationDelegate callInviteReceived:error:]` asynchronously on the dispatch queue
//     * with a `TVOCancelledCallInvite` if the caller hangs up or the client encounters any other error before the called
//     * party could answer or reject the call.
//     */
//     NSLog(@"cancelledCallInviteReceived");
//     TVOCallInvite *callInvite;
//     for (NSString *activeCallInviteId in self.activeCallInvites) {
//         TVOCallInvite *activeCallInvite = [self.activeCallInvites objectForKey:activeCallInviteId];
//         if ([cancelledCallInvite.callSid isEqualToString:activeCallInvite.callSid]) {
//             callInvite = activeCallInvite;
//             break;
//         }
//     }
//     if (callInvite) {
//         [self performEndCallActionWithUUID:callInvite.uuid];
//         NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
//         if (callInvite.callSid) {
//             [params setObject:callInvite.callSid forKey:@"call_sid"];
//         }
//         if (callInvite.from) {
//             [params setObject:callInvite.from forKey:@"call_from"];
//         }
//         if (callInvite.to) {
//             [params setObject:callInvite.to forKey:@"call_to"];
//         }
//         [self sendEventWithName:@"callInviteCancelled" body:params];
//     }
// }


// - (void)cancelledCallInviteReceived:(TVOCancelledCallInvite *)cancelledCallInvite error:(NSError *)error {
//     /**
//     * The SDK may call `[TVONotificationDelegate callInviteReceived:error:]` asynchronously on the dispatch queue
//     * with a `TVOCancelledCallInvite` if the caller hangs up or the client encounters any other error before the called
//     * party could answer or reject the call.
//     */
//     NSLog(@"cancelledCallInviteReceived with error %@", error);
//     TVOCallInvite *callInvite;
//     for (NSString *activeCallInviteId in self.activeCallInvites) {
//         TVOCallInvite *activeCallInvite = [self.activeCallInvites objectForKey:activeCallInviteId];
//         if ([cancelledCallInvite.callSid isEqualToString:activeCallInvite.callSid]) {
//             callInvite = activeCallInvite;
//             break;
//         }
//     }
//     if (callInvite) {
//         [self performEndCallActionWithUUID:callInvite.uuid];
//         NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
//         if (callInvite.callSid) {
//             [params setObject:callInvite.callSid forKey:@"call_sid"];
//         }
//         if (callInvite.from) {
//             [params setObject:callInvite.from forKey:@"call_from"];
//         }
//         if (callInvite.to) {
//             [params setObject:callInvite.to forKey:@"call_to"];
//         }
//         [self sendEventWithName:@"callInviteCancelled" body:params];
//     }
// }

// - (void)notificationError:(NSError *)error {
//   NSLog(@"notificationError: %@", [error localizedDescription]);
// }

// #pragma mark - TVOCallDelegate
// - (void)callDidStartRinging:(TVOCall *)call {
//     NSLog(@"callDidStartRinging");

//     /*
//      When [answerOnBridge](https://www.twilio.com/docs/voice/twiml/dial#answeronbridge) is enabled in the
//      <Dial> TwiML verb, the caller will not hear the ringback while the call is ringing and awaiting to be
//      accepted on the callee's side. The application can use the `AVAudioPlayer` to play custom audio files
//      between the `[TVOCallDelegate callDidStartRinging:]` and the `[TVOCallDelegate callDidConnect:]` callbacks.
//      */
//     NSMutableDictionary *callParams = [[NSMutableDictionary alloc] init];
//     [callParams setObject:call.sid forKey:@"call_sid"];
//     if (call.from) {
//         [callParams setObject:call.from forKey:@"call_from"];
//     }
//     [self sendEventWithName:@"callStateRinging" body:callParams];
// }

// #pragma mark - TVOCallDelegate
// - (void)callDidConnect:(TVOCall *)call {
//      NSLog(@"callDidConnect");
//   self.callKitCompletionCallback(YES);

//   NSMutableDictionary *callParams = [[NSMutableDictionary alloc] init];
//   [callParams setObject:call.sid forKey:@"call_sid"];
//   if (call.state == TVOCallStateConnecting) {
//     [callParams setObject:StateConnecting forKey:@"call_state"];
//   } else if (call.state == TVOCallStateConnected) {
//     [callParams setObject:StateConnected forKey:@"call_state"];
//   }

//   if (call.from) {
//     [callParams setObject:call.from forKey:@"call_from"];
//   }
//   if (call.to) {
//     [callParams setObject:call.to forKey:@"call_to"];
//   }
//   [self sendEventWithName:@"connectionDidConnect" body:callParams];
// }

// - (void)call:(TVOCall *)call isReconnectingWithError:(NSError *)error {
//     NSLog(@"Call is reconnecting");
//     NSMutableDictionary *callParams = [[NSMutableDictionary alloc] init];
//     [callParams setObject:call.sid forKey:@"call_sid"];
//     if (call.from) {
//       [callParams setObject:call.from forKey:@"call_from"];
//     }
//     if (call.to) {
//       [callParams setObject:call.to forKey:@"call_to"];
//     }
//     [self sendEventWithName:@"connectionIsReconnecting" body:callParams];
// }

// - (void)callDidReconnect:(TVOCall *)call {
//     NSLog(@"Call reconnected");
//     NSMutableDictionary *callParams = [[NSMutableDictionary alloc] init];
//     [callParams setObject:call.sid forKey:@"call_sid"];
//     if (call.from) {
//       [callParams setObject:call.from forKey:@"call_from"];
//     }
//     if (call.to) {
//       [callParams setObject:call.to forKey:@"call_to"];
//     }
//     [self sendEventWithName:@"connectionDidReconnect" body:callParams];
// }

// - (void)call:(TVOCall *)call didFailToConnectWithError:(NSError *)error {
//   NSLog(@"Call failed to connect: %@", error);

//   self.callKitCompletionCallback(NO);
//     [self performEndCallActionWithUUID:call.uuid];
//     [self callDisconnected:call error:error];
// }

// - (void)call:(TVOCall *)call didDisconnectWithError:(NSError *)error {
//     if (error) {
//         NSLog(@"didDisconnectWithError: %@", error);
//     } else {
//         NSLog(@"didDisconnect");
//     }

//     UIDevice* device = [UIDevice currentDevice];
//     device.proximityMonitoringEnabled = NO;

//     if (!self.userInitiatedDisconnect) {
//         CXCallEndedReason reason = CXCallEndedReasonRemoteEnded;
//         if (error) {
//             reason = CXCallEndedReasonFailed;
//         }
//         [self.callKitProvider reportCallWithUUID:call.uuid endedAtDate:[NSDate date] reason:reason];
//     }
//     [self callDisconnected:call error:error];
// }

// - (void)callDisconnected:(TVOCall *)call error:(NSError *)error {
//     NSLog(@"callDisconnect");
//     if ([call isEqual:self.activeCall]) {
//         self.activeCall = nil;
//     }
//     [self.activeCalls removeObjectForKey:call.uuid.UUIDString];

//     self.userInitiatedDisconnect = NO;

//     NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
//     if (error) {
//         NSString* errMsg = [error localizedDescription];
//         if (error.localizedFailureReason) {
//           errMsg = [error localizedFailureReason];
//         }
//         [params setObject:errMsg forKey:@"err"];
//     }
//     if (call.sid) {
//         [params setObject:call.sid forKey:@"call_sid"];
//     }
//     if (call.to) {
//         [params setObject:call.to forKey:@"call_to"];
//     }
//     if (call.from) {
//         [params setObject:call.from forKey:@"call_from"];
//     }
//     if (call.state == TVOCallStateDisconnected) {
//         [params setObject:StateDisconnected forKey:@"call_state"];
//     }
//     [self sendEventWithName:@"connectionDidDisconnect" body:params];
// }

// #pragma mark - AVAudioSession
// - (void)toggleAudioRoute:(BOOL)toSpeaker {
//     // The mode set by the Voice SDK is "VoiceChat" so the default audio route is the built-in receiver.
//     // Use port override to switch the route.
//     self.audioDevice.block =  ^ {
//         // We will execute `kDefaultAVAudioSessionConfigurationBlock` first.
//         kTVODefaultAVAudioSessionConfigurationBlock();

//         // Overwrite the audio route
//         AVAudioSession *session = [AVAudioSession sharedInstance];
//         NSError *error = nil;
//         if (toSpeaker) {
//             if (![session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error]) {
//                 NSLog(@"Unable to reroute audio: %@", [error localizedDescription]);
//             }
//         } else {
//             if (![session overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&error]) {
//                 NSLog(@"Unable to reroute audio: %@", [error localizedDescription]);
//             }
//         }
//     };
//     self.audioDevice.block();
// }

// #pragma mark - CXProviderDelegate
// - (void)providerDidReset:(CXProvider *)provider {
//   NSLog(@"providerDidReset");
//     self.audioDevice.enabled = YES;
// }

// - (void)providerDidBegin:(CXProvider *)provider {
//   NSLog(@"providerDidBegin");
// }

// - (void)provider:(CXProvider *)provider didActivateAudioSession:(AVAudioSession *)audioSession {
//   NSLog(@"provider:didActivateAudioSession");
//     self.audioDevice.enabled = YES;
// }

// - (void)provider:(CXProvider *)provider didDeactivateAudioSession:(AVAudioSession *)audioSession {
//   NSLog(@"provider:didDeactivateAudioSession");
//     self.audioDevice.enabled = NO;
// }

// - (void)provider:(CXProvider *)provider timedOutPerformingAction:(CXAction *)action {
//   NSLog(@"provider:timedOutPerformingAction");
// }

// - (void)provider:(CXProvider *)provider performStartCallAction:(CXStartCallAction *)action {
//   NSLog(@"provider:performStartCallAction");

//     self.audioDevice.enabled = NO;
//     self.audioDevice.block();

//   [self.callKitProvider reportOutgoingCallWithUUID:action.callUUID startedConnectingAtDate:[NSDate date]];

//   __weak typeof(self) weakSelf = self;
//   [self performVoiceCallWithUUID:action.callUUID client:nil completion:^(BOOL success) {
//     __strong typeof(self) strongSelf = weakSelf;
//     if (success) {
//       [strongSelf.callKitProvider reportOutgoingCallWithUUID:action.callUUID connectedAtDate:[NSDate date]];
//       [action fulfill];
//     } else {
//       [action fail];
//     }
//   }];
// }

// - (void)provider:(CXProvider *)provider performAnswerCallAction:(CXAnswerCallAction *)action {
//   NSLog(@"provider:performAnswerCallAction");

//   self.audioDevice.enabled = NO;
//   self.audioDevice.block();
//   [self performAnswerVoiceCallWithUUID:action.callUUID completion:^(BOOL success) {
//     if (success) {
//       [action fulfill];
//     } else {
//       [action fail];
//     }
//   }];

//   [action fulfill];
// }

// - (void)provider:(CXProvider *)provider performEndCallAction:(CXEndCallAction *)action {
//   NSLog(@"provider:performEndCallAction");

//     TVOCallInvite *callInvite = self.activeCallInvites[action.callUUID.UUIDString];
//     TVOCall *call = self.activeCalls[action.callUUID.UUIDString];

//     if (callInvite) {
//         [callInvite reject];
//         [self sendEventWithName:@"callRejected" body:@"callRejected"];
//         [self.activeCallInvites removeObjectForKey:callInvite.uuid.UUIDString];
//     } else if (call) {
//         [call disconnect];
//     } else {
//         NSLog(@"Unknown UUID to perform end-call action with");
//     }

//     self.audioDevice.enabled = YES;
//   [action fulfill];
// }

// - (void)provider:(CXProvider *)provider performSetHeldCallAction:(CXSetHeldCallAction *)action {
//     TVOCall *call = self.activeCalls[action.callUUID.UUIDString];
//   if (call) {
//     [call setOnHold:action.isOnHold];
//     [action fulfill];
//   } else {
//     [action fail];
//   }
// }

// - (void)provider:(CXProvider *)provider performSetMutedCallAction:(CXSetMutedCallAction *)action {
//     TVOCall *call = self.activeCalls[action.callUUID.UUIDString];
//     if (call) {
//         [call setMuted:action.isMuted];
//         [action fulfill];
//     } else {
//         [action fail];
//     }
// }

// - (void)provider:(CXProvider *)provider performPlayDTMFCallAction:(CXPlayDTMFCallAction *)action {
//   TVOCall *call = self.activeCalls[action.callUUID.UUIDString];
//   if (call && call.state == TVOCallStateConnected) {
//     NSLog(@"SendDigits %@", action.digits);
//     [call sendDigits:action.digits];
//   }
// }

// #pragma mark - CallKit Actions
// - (void)performStartCallActionWithUUID:(NSUUID *)uuid handle:(NSString *)handle {
//   if (uuid == nil || handle == nil) {
//     return;
//   }

//   CXHandle *callHandle = [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:handle];
//   CXStartCallAction *startCallAction = [[CXStartCallAction alloc] initWithCallUUID:uuid handle:callHandle];
//   CXTransaction *transaction = [[CXTransaction alloc] initWithAction:startCallAction];

//   [self.callKitCallController requestTransaction:transaction completion:^(NSError *error) {
//     if (error) {
//       NSLog(@"StartCallAction transaction request failed: %@", [error localizedDescription]);
//     } else {
//       NSLog(@"StartCallAction transaction request successful");

//       CXCallUpdate *callUpdate = [[CXCallUpdate alloc] init];
//       callUpdate.remoteHandle = callHandle;
//       callUpdate.supportsDTMF = YES;
//       callUpdate.supportsHolding = YES;
//       callUpdate.supportsGrouping = NO;
//       callUpdate.supportsUngrouping = NO;
//       callUpdate.hasVideo = NO;

//       [self.callKitProvider reportCallWithUUID:uuid updated:callUpdate];
//     }
//   }];
// }

// - (void)reportIncomingCallFrom:(NSString *)from withUUID:(NSUUID *)uuid {
//   CXHandleType type = [[from substringToIndex:1] isEqual:@"+"] ? CXHandleTypePhoneNumber : CXHandleTypeGeneric;
//   // lets replace 'client:' with ''
//   CXHandle *callHandle = [[CXHandle alloc] initWithType:type value:[from stringByReplacingOccurrencesOfString:@"client:" withString:@""]];

//   CXCallUpdate *callUpdate = [[CXCallUpdate alloc] init];
//   callUpdate.remoteHandle = callHandle;
//   callUpdate.supportsDTMF = YES;
//   callUpdate.supportsHolding = YES;
//   callUpdate.supportsGrouping = NO;
//   callUpdate.supportsUngrouping = NO;
//   callUpdate.hasVideo = NO;

//   [self.callKitProvider reportNewIncomingCallWithUUID:uuid update:callUpdate completion:^(NSError *error) {
//     if (!error) {
//       NSLog(@"Incoming call successfully reported");
//     } else {
//       NSLog(@"Failed to report incoming call successfully: %@.", [error localizedDescription]);
//     }
//   }];
// }

// - (void)performEndCallActionWithUUID:(NSUUID *)uuid {
//   if (uuid == nil) {
//     return;
//   }

//   CXEndCallAction *endCallAction = [[CXEndCallAction alloc] initWithCallUUID:uuid];
//   CXTransaction *transaction = [[CXTransaction alloc] initWithAction:endCallAction];

//   [self.callKitCallController requestTransaction:transaction completion:^(NSError *error) {
//     if (error) {
//       NSLog(@"EndCallAction transaction request failed: %@", [error localizedDescription]);
//     }
//   }];
// }

// - (void)performVoiceCallWithUUID:(NSUUID *)uuid
//                           client:(NSString *)client
//                       completion:(void(^)(BOOL success))completionHandler {
//                           __weak typeof(self) weakSelf = self;
//     TVOConnectOptions *connectOptions = [TVOConnectOptions optionsWithAccessToken:[self fetchAccessToken] block:^(TVOConnectOptionsBuilder *builder) {
//       __strong typeof(self) strongSelf = weakSelf;
//       builder.params = strongSelf->_callParams;
//       builder.uuid = uuid;
//     }];
//     TVOCall *call = [TwilioVoice connectWithOptions:connectOptions delegate:self];
//     if (call) {
//       self.activeCall = call;
//       self.activeCalls[call.uuid.UUIDString] = call;
//     }
//     self.callKitCompletionCallback = completionHandler;
// }

// - (void)performAnswerVoiceCallWithUUID:(NSUUID *)uuid
//                             completion:(void(^)(BOOL success))completionHandler {

//     TVOCallInvite *callInvite = self.activeCallInvites[uuid.UUIDString];
//     NSAssert(callInvite, @"No CallInvite matches the UUID");
//     TVOAcceptOptions *acceptOptions = [TVOAcceptOptions optionsWithCallInvite:callInvite block:^(TVOAcceptOptionsBuilder *builder) {
//         builder.uuid = callInvite.uuid;
//     }];

//     TVOCall *call = [callInvite acceptWithOptions:acceptOptions delegate:self];

//     if (!call) {
//         completionHandler(NO);
//     } else {
//         self.callKitCompletionCallback = completionHandler;
//         self.activeCall = call;
//         self.activeCalls[call.uuid.UUIDString] = call;
//     }

//     [self.activeCallInvites removeObjectForKey:callInvite.uuid.UUIDString];

//     if ([[NSProcessInfo processInfo] operatingSystemVersion].majorVersion < 13) {
//         [self incomingPushHandled];
//     }
// }

// - (void)handleAppTerminateNotification {
//   NSLog(@"handleAppTerminateNotification called");

//   if (self.activeCall) {
//     NSLog(@"handleAppTerminateNotification disconnecting an active call");
//     [self.activeCall disconnect];
//   }
// }

@end





@implementation ViewController

- (instancetype)initWithToken: (NSString *)token {
    self = [super init];
  if (self) {
    self.kAccessToken = token;
  }
  return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self toggleUIState:YES showCallControl:NO];
    self.outgoingValue.delegate = self;
}

- (void)configureCallKit: (NSDictionary *)params {
    NSLog(@"configureCallKit %@", params);

    self.callKitCallController = [[CXCallController alloc] init];
    /* Please note that the designated initializer `[CXProviderConfiguration initWithLocalizedName:]` has been deprecated on iOS 14. */
    CXProviderConfiguration *configuration = [[CXProviderConfiguration alloc] initWithLocalizedName:@"Voice Quickstart"];
    configuration.maximumCallGroups = 1;
    configuration.maximumCallsPerCallGroup = 1;

    self.callKitProvider = [[CXProvider alloc] initWithConfiguration:configuration];
    [self.callKitProvider setDelegate:self queue:nil];

    /*
     * The important thing to remember when providing a TVOAudioDevice is that the device must be set
     * before performing any other actions with the SDK (such as connecting a Call, or accepting an incoming Call).
     * In this case we've already initialized our own `TVODefaultAudioDevice` instance which we will now set.
     */
    self.audioDevice = [TVODefaultAudioDevice audioDevice];
    TwilioVoice.audioDevice = self.audioDevice;

    self.activeCallInvites = [NSMutableDictionary dictionary];
    self.activeCalls = [NSMutableDictionary dictionary];

    /*
     Custom ringback will be played when this flag is enabled.
     When [answerOnBridge](https://www.twilio.com/docs/voice/twiml/dial#answeronbridge) is enabled in
     the <Dial> TwiML verb, the caller will not hear the ringback while the call is ringing and awaiting
     to be accepted on the callee's side. Configure this flag based on the TwiML application.
     */
    self.playCustomRingback = NO;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    if (self.callKitProvider) {
        [self.callKitProvider invalidate];
    }
}

- (void)setAccess:(NSString *)access {
  self.kAccessToken = access;
}

- (IBAction)mainButtonPressed:(id)sender {
    if (self.activeCall != nil) {
        self.userInitiatedDisconnect = YES;
        [self performEndCallActionWithUUID:self.activeCall.uuid];
        [self toggleUIState:NO showCallControl:NO];
    } else {
        NSUUID *uuid = [NSUUID UUID];
        NSString *handle = @"Voice Bot";

        [self checkRecordPermission:^(BOOL permissionGranted) {
            if (!permissionGranted) {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Voice Quick Start"
                                                                                         message:@"Microphone permission not granted."
                                                                                  preferredStyle:UIAlertControllerStyleAlert];

                typeof(self) __weak weakSelf = self;
                UIAlertAction *continueWithoutMic = [UIAlertAction actionWithTitle:@"Continue without microphone"
                                                                             style:UIAlertActionStyleDefault
                                                                           handler:^(UIAlertAction *action) {
                    typeof(self) __strong strongSelf = weakSelf;
                    [strongSelf performStartCallActionWithUUID:uuid handle:handle];
                }];
                [alertController addAction:continueWithoutMic];

                NSDictionary *openURLOptions = @{UIApplicationOpenURLOptionUniversalLinksOnly: @NO};
                UIAlertAction *goToSettings = [UIAlertAction actionWithTitle:@"Settings"
                                                                       style:UIAlertActionStyleDefault
                                                                     handler:^(UIAlertAction *action) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]
                                                       options:openURLOptions
                                             completionHandler:nil];
                }];
                [alertController addAction:goToSettings];

                UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                                 style:UIAlertActionStyleCancel
                                                               handler:^(UIAlertAction *action) {
                    typeof(self) __strong strongSelf = weakSelf;
                    [strongSelf toggleUIState:YES showCallControl:NO];
                    [strongSelf stopSpin];
                }];
                [alertController addAction:cancel];

                [self presentViewController:alertController animated:YES completion:nil];
            } else {
                [self performStartCallActionWithUUID:uuid handle:handle];
            }
        }];
    }
}

- (void)checkRecordPermission:(void(^)(BOOL permissionGranted))completion {
    AVAudioSessionRecordPermission permissionStatus = [[AVAudioSession sharedInstance] recordPermission];
    switch (permissionStatus) {
        case AVAudioSessionRecordPermissionGranted:
            // Record permission already granted.
            completion(YES);
            break;
        case AVAudioSessionRecordPermissionDenied:
            // Record permission denied.
            completion(NO);
            break;
        case AVAudioSessionRecordPermissionUndetermined:
        {
            // Requesting record permission.
            // Optional: pop up app dialog to let the users know if they want to request.
            [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
                completion(granted);
            }];
            break;
        }
        default:
            completion(NO);
            break;
    }
}

- (void)toggleUIState:(BOOL)isEnabled showCallControl:(BOOL)showCallControl {
    self.placeCallButton.enabled = isEnabled;
    if (showCallControl) {
        self.callControlView.hidden = NO;
        self.muteSwitch.on = NO;
        self.speakerSwitch.on = YES;
    } else {
        self.callControlView.hidden = YES;
    }
}

- (IBAction)muteSwitchToggled:(UISwitch *)sender {
    // The sample app supports toggling mute from app UI only on the last connected call.
    if (self.activeCall != nil) {
        self.activeCall.muted = sender.on;
    }
}

- (IBAction)speakerSwitchToggled:(UISwitch *)sender {
    [self toggleAudioRoute:sender.on];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.outgoingValue resignFirstResponder];
    return YES;
}

#pragma mark - PushKitEventDelegate
- (void)credentialsUpdated:(PKPushCredentials *)credentials {
    NSData *cachedDeviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:kCachedDeviceToken];
    if ([self registrationRequired] || ![cachedDeviceToken isEqualToData:credentials.token]) {
        cachedDeviceToken = credentials.token;

        /*
         * Perform registration if a new device token is detected.
         */
        [TwilioVoice registerWithAccessToken:self.kAccessToken
                                    deviceToken:cachedDeviceToken
                                     completion:^(NSError *error) {
             if (error) {
                 NSLog(@"An error occurred while registering: %@", [error localizedDescription]);
             } else {
                 NSLog(@"Successfully registered for VoIP push notifications.");

                 // Save the device token after successfully registered.
                 [[NSUserDefaults standardUserDefaults] setObject:cachedDeviceToken forKey:kCachedDeviceToken];

                 /**
                  * The TTL of a registration is 1 year. The TTL for registration for this device/identity
                  * pair is reset to 1 year whenever a new registration occurs or a push notification is
                  * sent to this device/identity pair.
                  */
                 [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kCachedBindingTime];
             }
        }];
    }
}

/**
 * The TTL of a registration is 1 year. The TTL for registration for this device/identity pair is reset to
 * 1 year whenever a new registration occurs or a push notification is sent to this device/identity pair.
 * This method checks if binding exists in UserDefaults, and if half of TTL has been passed then the method
 * will return true, else false.
 */
- (BOOL)registrationRequired {
    BOOL registrationRequired = YES;
    NSDate *lastBindingCreated = [[NSUserDefaults standardUserDefaults] objectForKey:kCachedBindingTime];

    if (lastBindingCreated) {
        NSDateComponents *dayComponent = [[NSDateComponents alloc] init];

        // Register upon half of the TTL
        dayComponent.day = kRegistrationTTLInDays / 2;

        NSDate *bindingExpirationDate = [[NSCalendar currentCalendar] dateByAddingComponents:dayComponent toDate:lastBindingCreated options:0];
        NSDate *currentDate = [NSDate date];
        if ([bindingExpirationDate compare:currentDate] == NSOrderedDescending) {
            registrationRequired = NO;
        }
    }
    return registrationRequired;
}

- (void)credentialsInvalidated {
    NSData *cachedDeviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:kCachedDeviceToken];
    if ([cachedDeviceToken length] > 0) {
        [TwilioVoice unregisterWithAccessToken:self.kAccessToken
                                      deviceToken:cachedDeviceToken
                                       completion:^(NSError *error) {
            if (error) {
                NSLog(@"An error occurred while unregistering: %@", [error localizedDescription]);
            } else {
                NSLog(@"Successfully unregistered for VoIP push notifications.");
            }
        }];
    }

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCachedDeviceToken];

    // Remove the cached binding as credentials are invalidated
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCachedBindingTime];
}

- (void)incomingPushReceived:(PKPushPayload *)payload withCompletionHandler:(void (^)(void))completion {
    // The Voice SDK will use main queue to invoke `cancelledCallInviteReceived:error` when delegate queue is not passed
    if (![TwilioVoice handleNotification:payload.dictionaryPayload delegate:self delegateQueue:nil]) {
        NSLog(@"This is not a valid Twilio Voice notification.");
    }

    if (completion) {
        if ([[NSProcessInfo processInfo] operatingSystemVersion].majorVersion < 13) {
            // Save for later when the notification is properly handled.
            self.incomingPushCompletionCallback = completion;
        } else {
            /*
             * The Voice SDK processes the call notification and returns the call invite synchronously.
             * Report the incoming call to CallKit and fulfill the completion before exiting this callback method.
             */
            completion();
        }
    }
}

- (void)incomingPushHandled {
    if (self.incomingPushCompletionCallback) {
        self.incomingPushCompletionCallback();
        self.incomingPushCompletionCallback = nil;
    }
}

#pragma mark - TVONotificationDelegate
- (void)callInviteReceived:(TVOCallInvite *)callInvite {

    /**
     * Calling `[TwilioVoiceSDK handleNotification:delegate:]` will synchronously process your notification payload and
     * provide you a `TVOCallInvite` object. Report the incoming call to CallKit upon receiving this callback.
     */

    NSLog(@"callInviteReceived:");

    /**
     * The TTL of a registration is 1 year. The TTL for registration for this device/identity
     * pair is reset to 1 year whenever a new registration occurs or a push notification is
     * sent to this device/identity pair.
     */
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kCachedBindingTime];

    if (callInvite.callerInfo.verified != nil && [callInvite.callerInfo.verified boolValue]) {
        NSLog(@"Call invite received from verified caller number!");
    }

    NSString *from = @"Voice Bot";
    if (callInvite.from) {
        from = [callInvite.from stringByReplacingOccurrencesOfString:@"client:" withString:@""];
    }

    // Always report to CallKit
    [self reportIncomingCallFrom:from withUUID:callInvite.uuid];
    self.activeCallInvites[[callInvite.uuid UUIDString]] = callInvite;
    if ([[NSProcessInfo processInfo] operatingSystemVersion].majorVersion < 13) {
        [self incomingPushHandled];
    }
}

- (void)cancelledCallInviteReceived:(TVOCancelledCallInvite *)cancelledCallInvite error:(NSError *)error {

    /**
     * The SDK may call `[TVONotificationDelegate callInviteReceived:error:]` asynchronously on the dispatch queue
     * with a `TVOCancelledCallInvite` if the caller hangs up or the client encounters any other error before the called
     * party could answer or reject the call.
     */

    NSLog(@"cancelledCallInviteReceived:");

    TVOCallInvite *callInvite;
    for (NSString *uuid in self.activeCallInvites) {
        TVOCallInvite *activeCallInvite = [self.activeCallInvites objectForKey:uuid];
        if ([cancelledCallInvite.callSid isEqualToString:activeCallInvite.callSid]) {
            callInvite = activeCallInvite;
            break;
        }
    }

    if (callInvite) {
        [self performEndCallActionWithUUID:callInvite.uuid];
        [self.activeCallInvites removeObjectForKey:callInvite.uuid.UUIDString];
    }
}

#pragma mark - TVOCallDelegate
- (void)callDidStartRinging:(TVOCall *)call {
    NSLog(@"callDidStartRinging:");

    /*
     When [answerOnBridge](https://www.twilio.com/docs/voice/twiml/dial#answeronbridge) is enabled in the
     <Dial> TwiML verb, the caller will not hear the ringback while the call is ringing and awaiting to be
     accepted on the callee's side. The application can use the `AVAudioPlayer` to play custom audio files
     between the `[TVOCallDelegate callDidStartRinging:]` and the `[TVOCallDelegate callDidConnect:]` callbacks.
     */
    if (self.playCustomRingback) {
        [self playRingback];
    }

    [self.placeCallButton setTitle:@"Ringing" forState:UIControlStateNormal];
}

- (void)callDidConnect:(TVOCall *)call {
    NSLog(@"callDidConnect:");

    if (self.playCustomRingback) {
        [self stopRingback];
    }

    self.callKitCompletionCallback(YES);

    [self.placeCallButton setTitle:@"Hang Up" forState:UIControlStateNormal];

    [self toggleUIState:YES showCallControl:YES];
    [self stopSpin];
    [self toggleAudioRoute:YES];
}

- (void)call:(TVOCall *)call isReconnectingWithError:(NSError *)error {
    NSLog(@"Call is reconnecting");

    [self.placeCallButton setTitle:@"Reconnecting" forState:UIControlStateNormal];
    [self toggleUIState:NO showCallControl:NO];
}

- (void)callDidReconnect:(TVOCall *)call {
    NSLog(@"Call reconnected");

    [self.placeCallButton setTitle:@"Hang Up" forState:UIControlStateNormal];
    [self toggleUIState:YES showCallControl:YES];
}

- (void)call:(TVOCall *)call didFailToConnectWithError:(NSError *)error {
    NSLog(@"Call failed to connect: %@", error);

    self.callKitCompletionCallback(NO);
    [self.callKitProvider reportCallWithUUID:call.uuid endedAtDate:[NSDate date] reason:CXCallEndedReasonFailed];
    [self callDisconnected:call];
}

- (void)call:(TVOCall *)call didDisconnectWithError:(NSError *)error {
    if (error) {
        NSLog(@"Call failed: %@", error);
    } else {
        NSLog(@"Call disconnected");
    }

    if (!self.userInitiatedDisconnect) {
        CXCallEndedReason reason = CXCallEndedReasonRemoteEnded;
        if (error) {
            reason = CXCallEndedReasonFailed;
        }

        [self.callKitProvider reportCallWithUUID:call.uuid endedAtDate:[NSDate date] reason:reason];
    }

    [self callDisconnected:call];
}

- (void)callDisconnected:(TVOCall *)call {
    if ([call isEqual:self.activeCall]) {
        self.activeCall = nil;
    }
    [self.activeCalls removeObjectForKey:call.uuid.UUIDString];

    self.userInitiatedDisconnect = NO;

    if (self.playCustomRingback) {
        [self stopRingback];
    }

    [self stopSpin];
    [self toggleUIState:YES showCallControl:NO];
    [self.placeCallButton setTitle:@"Call" forState:UIControlStateNormal];
}

- (void)call:(TVOCall *)call
didReceiveQualityWarnings:(NSSet<NSNumber *> *)currentWarnings
previousWarnings:(NSSet<NSNumber *> *)previousWarnings {
    /**
     * currentWarnings: existing quality warnings that have not been cleared yet
     * previousWarnings: last set of warnings prior to receiving this callback
     *
     * Example:
     *   - currentWarnings: { A, B }
     *   - previousWarnings: { B, C }
     *   - intersection: { B }
     *
     * Newly raised warnings = currentWarnings - intersection = { A }
     * Newly cleared warnings = previousWarnings - intersection = { C }
     */
    NSMutableSet *warningIntersetction = [currentWarnings mutableCopy];
    [warningIntersetction intersectSet:previousWarnings];

    NSMutableSet *newWarnings = [currentWarnings mutableCopy];
    [newWarnings minusSet:warningIntersetction];
    if ([newWarnings count] > 0) {
        [self qualityWarningUpdatePopup:newWarnings isCleared:NO];
    }

    NSMutableSet *clearedWarnings = [previousWarnings mutableCopy];
    [clearedWarnings minusSet:warningIntersetction];
    if ([clearedWarnings count] > 0) {
        [self qualityWarningUpdatePopup:clearedWarnings isCleared:YES];
    }
}

- (void)qualityWarningUpdatePopup:(NSSet *)warnings isCleared:(BOOL)cleared {
    NSString *popupMessage = (cleared)? @"Warnings cleared:" : @"Warnings detected:";
    for (NSNumber *warning in warnings) {
        NSString *warningName = [self warningString: warning];
        popupMessage = [popupMessage stringByAppendingString:[NSString stringWithFormat:@" %@", warningName]];
    }

    self.qualityWarningsToaster.alpha = 0.0f;
    self.qualityWarningsToaster.text = popupMessage;
    [UIView animateWithDuration:1.0f
                     animations:^{
        self.qualityWarningsToaster.hidden = NO;
        self.qualityWarningsToaster.alpha = 1.0f;
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:1.0 animations:^{
                self.qualityWarningsToaster.alpha = 0.0f;
            } completion:^(BOOL finished) {
                self.qualityWarningsToaster.hidden = YES;
            }];
        });
    }];
}

- (NSString *)warningString:(NSNumber*)qualityWarning {
    int intValue = [qualityWarning intValue];
    switch (intValue) {
        case 0:
            return @"high-rtt";
            break;
        case 1:
            return @"high-jitter";
            break;
        case 2:
            return @"high-packets-lost-fraction";
            break;
        case 3:
            return @"low-mos";
            break;
        case 4:
            return @"constant-audio-input-level";
            break;
        default:
            return @"Unknown warning";
            break;
    }
}

#pragma mark - AVAudioSession
- (void)toggleAudioRoute:(BOOL)toSpeaker {
    // The mode set by the Voice SDK is "VoiceChat" so the default audio route is the built-in receiver. Use port override to switch the route.
    self.audioDevice.block =  ^ {
        // We will execute `kDefaultAVAudioSessionConfigurationBlock` first.
        kTVODefaultAVAudioSessionConfigurationBlock();

        // Overwrite the audio route
        AVAudioSession *session = [AVAudioSession sharedInstance];
        NSError *error = nil;
        if (toSpeaker) {
            if (![session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error]) {
                NSLog(@"Unable to reroute audio: %@", [error localizedDescription]);
            }
        } else {
            if (![session overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&error]) {
                NSLog(@"Unable to reroute audio: %@", [error localizedDescription]);
            }
        }
    };
    self.audioDevice.block();
}

#pragma mark - Icon spinning
- (void)startSpin {
    if (!self.isSpinning) {
        self.spinning = YES;
        [self spinWithOptions:UIViewAnimationOptionCurveEaseIn];
    }
}

- (void)stopSpin {
    self.spinning = NO;
}

- (void)spinWithOptions:(UIViewAnimationOptions)options {
    typeof(self) __weak weakSelf = self;

    [UIView animateWithDuration:0.5f
                          delay:0.0f
                        options:options
                     animations:^{
                         typeof(self) __strong strongSelf = weakSelf;
                         strongSelf.iconView.transform = CGAffineTransformRotate(strongSelf.iconView.transform, M_PI / 2);
                     }
                     completion:^(BOOL finished) {
                         typeof(self) __strong strongSelf = weakSelf;
                         if (finished) {
                             if (strongSelf.isSpinning) {
                                 [strongSelf spinWithOptions:UIViewAnimationOptionCurveLinear];
                             } else if (options != UIViewAnimationOptionCurveEaseOut) {
                                 [strongSelf spinWithOptions:UIViewAnimationOptionCurveEaseOut];
                             }
                         }
                     }];
}

#pragma mark - CXProviderDelegate
- (void)providerDidReset:(CXProvider *)provider {
    NSLog(@"providerDidReset:");
    self.audioDevice.enabled = NO;
}

- (void)providerDidBegin:(CXProvider *)provider {
    NSLog(@"providerDidBegin:");
}

- (void)provider:(CXProvider *)provider didActivateAudioSession:(AVAudioSession *)audioSession {
    NSLog(@"provider:didActivateAudioSession:");
    self.audioDevice.enabled = YES;
}

- (void)provider:(CXProvider *)provider didDeactivateAudioSession:(AVAudioSession *)audioSession {
    NSLog(@"provider:didDeactivateAudioSession:");
    self.audioDevice.enabled = NO;
}

- (void)provider:(CXProvider *)provider timedOutPerformingAction:(CXAction *)action {
    NSLog(@"provider:timedOutPerformingAction:");
}

- (void)provider:(CXProvider *)provider performStartCallAction:(CXStartCallAction *)action {
    NSLog(@"provider:performStartCallAction:");

    [self toggleUIState:NO showCallControl:NO];
    [self startSpin];

    [self.callKitProvider reportOutgoingCallWithUUID:action.callUUID startedConnectingAtDate:[NSDate date]];

    __weak typeof(self) weakSelf = self;
    [self performVoiceCallWithUUID:action.callUUID client:nil completion:^(BOOL success) {
        __strong typeof(self) strongSelf = weakSelf;
        if (success) {
            NSLog(@"performVoiceCallWithUUID successful");
            [strongSelf.callKitProvider reportOutgoingCallWithUUID:action.callUUID connectedAtDate:[NSDate date]];
        } else {
            NSLog(@"performVoiceCallWithUUID failed");
        }
        [action fulfill];
    }];
}

- (void)provider:(CXProvider *)provider performAnswerCallAction:(CXAnswerCallAction *)action {
    NSLog(@"provider:performAnswerCallAction:");

    [self performAnswerVoiceCallWithUUID:action.callUUID completion:^(BOOL success) {
        if (success) {
            NSLog(@"performAnswerVoiceCallWithUUID successful");
        } else {
            NSLog(@"performAnswerVoiceCallWithUUID failed");
        }
    }];

    [action fulfill];
}

- (void)provider:(CXProvider *)provider performEndCallAction:(CXEndCallAction *)action {
    NSLog(@"provider:performEndCallAction:");

    TVOCallInvite *callInvite = self.activeCallInvites[action.callUUID.UUIDString];
    TVOCall *call = self.activeCalls[action.callUUID.UUIDString];

    if (callInvite) {
        [callInvite reject];
        [self.activeCallInvites removeObjectForKey:callInvite.uuid.UUIDString];
    } else if (call) {
        [call disconnect];
    } else {
        NSLog(@"Unknown UUID to perform end-call action with");
    }

    [action fulfill];
}

- (void)provider:(CXProvider *)provider performSetHeldCallAction:(CXSetHeldCallAction *)action {
    TVOCall *call = self.activeCalls[action.callUUID.UUIDString];
    if (call) {
        [call setOnHold:action.isOnHold];
        [action fulfill];
    } else {
        [action fail];
    }
}

- (void)provider:(CXProvider *)provider performSetMutedCallAction:(CXSetMutedCallAction *)action {
    TVOCall *call = self.activeCalls[action.callUUID.UUIDString];
    if (call) {
        [call setMuted:action.isMuted];
        [action fulfill];
    } else {
        [action fail];
    }
}

#pragma mark - CallKit Actions
- (void)performStartCallActionWithUUID:(NSUUID *)uuid handle:(NSString *)handle {
    if (uuid == nil || handle == nil) {
        return;
    }

    CXHandle *callHandle = [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:handle];
    CXStartCallAction *startCallAction = [[CXStartCallAction alloc] initWithCallUUID:uuid handle:callHandle];
    CXTransaction *transaction = [[CXTransaction alloc] initWithAction:startCallAction];

    [self.callKitCallController requestTransaction:transaction completion:^(NSError *error) {
        if (error) {
            NSLog(@"StartCallAction transaction request failed: %@", [error localizedDescription]);
        } else {
            NSLog(@"StartCallAction transaction request successful");

            CXCallUpdate *callUpdate = [[CXCallUpdate alloc] init];
            callUpdate.remoteHandle = callHandle;
            callUpdate.supportsDTMF = YES;
            callUpdate.supportsHolding = YES;
            callUpdate.supportsGrouping = NO;
            callUpdate.supportsUngrouping = NO;
            callUpdate.hasVideo = NO;

            [self.callKitProvider reportCallWithUUID:uuid updated:callUpdate];
        }
    }];
}

- (void)reportIncomingCallFrom:(NSString *) from withUUID:(NSUUID *)uuid {
    CXHandle *callHandle = [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:from];

    CXCallUpdate *callUpdate = [[CXCallUpdate alloc] init];
    callUpdate.remoteHandle = callHandle;
    callUpdate.supportsDTMF = YES;
    callUpdate.supportsHolding = YES;
    callUpdate.supportsGrouping = NO;
    callUpdate.supportsUngrouping = NO;
    callUpdate.hasVideo = NO;

    [self.callKitProvider reportNewIncomingCallWithUUID:uuid update:callUpdate completion:^(NSError *error) {
        if (!error) {
            NSLog(@"Incoming call successfully reported.");
        }
        else {
            NSLog(@"Failed to report incoming call successfully: %@.", [error localizedDescription]);
        }
    }];
}

- (void)performEndCallActionWithUUID:(NSUUID *)uuid {
    CXEndCallAction *endCallAction = [[CXEndCallAction alloc] initWithCallUUID:uuid];
    CXTransaction *transaction = [[CXTransaction alloc] initWithAction:endCallAction];

    [self.callKitCallController requestTransaction:transaction completion:^(NSError *error) {
        if (error) {
            NSLog(@"EndCallAction transaction request failed: %@", [error localizedDescription]);
        }
        else {
            NSLog(@"EndCallAction transaction request successful");
        }
    }];
}

- (void)performVoiceCallWithUUID:(NSUUID *)uuid
                          client:(NSString *)client
                      completion:(void(^)(BOOL success))completionHandler {
    __weak typeof(self) weakSelf = self;
    TVOConnectOptions *connectOptions = [TVOConnectOptions optionsWithAccessToken:self.kAccessToken block:^(TVOConnectOptionsBuilder *builder) {
        __strong typeof(self) strongSelf = weakSelf;
        builder.params = @{kTwimlParamTo: strongSelf.outgoingValue.text};
        builder.uuid = uuid;
    }];
    TVOCall *call = [TwilioVoice connectWithOptions:connectOptions delegate:self];
    if (call) {
        self.activeCall = call;
        self.activeCalls[call.uuid.UUIDString] = call;
    }
    self.callKitCompletionCallback = completionHandler;
}

- (void)performAnswerVoiceCallWithUUID:(NSUUID *)uuid
                            completion:(void(^)(BOOL success))completionHandler {
    TVOCallInvite *callInvite = self.activeCallInvites[uuid.UUIDString];
    NSAssert(callInvite, @"No CallInvite matches the UUID");

    TVOAcceptOptions *acceptOptions = [TVOAcceptOptions optionsWithCallInvite:callInvite block:^(TVOAcceptOptionsBuilder *builder) {
        builder.uuid = callInvite.uuid;
    }];

    TVOCall *call = [callInvite acceptWithOptions:acceptOptions delegate:self];

    if (!call) {
        completionHandler(NO);
    } else {
        self.callKitCompletionCallback = completionHandler;
        self.activeCall = call;
        self.activeCalls[call.uuid.UUIDString] = call;
    }

    [self.activeCallInvites removeObjectForKey:callInvite.uuid.UUIDString];

    if ([[NSProcessInfo processInfo] operatingSystemVersion].majorVersion < 13) {
        [self incomingPushHandled];
    }
}

#pragma mark - Ringtone

- (void)playRingback {
    NSString *ringtonePath = [[NSBundle mainBundle] pathForResource:@"ringtone" ofType:@"wav"];
    if ([ringtonePath length] <= 0) {
        NSLog(@"Can't find sound file");
        return;
    }

    NSError *error;
    self.ringtonePlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:ringtonePath] error:&error];
    if (error != nil) {
        NSLog(@"Failed to initialize audio player: %@", error);
    } else {
        self.ringtonePlayer.delegate = self;
        self.ringtonePlayer.numberOfLoops = -1;

        self.ringtonePlayer.volume = 1.0f;
        [self.ringtonePlayer play];
    }
}

- (void)stopRingback {
    if (!self.ringtonePlayer.isPlaying) {
        return;
    }

    [self.ringtonePlayer stop];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    if (flag) {
        NSLog(@"Audio player finished playing successfully");
    } else {
        NSLog(@"Audio player finished playing with some error");
    }
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    NSLog(@"Decode error occurred: %@", error);
}

@end

