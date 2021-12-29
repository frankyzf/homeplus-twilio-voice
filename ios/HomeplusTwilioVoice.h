#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

#import <UIKit/UIKit.h>

@import PushKit;

@protocol PushKitEventDelegate <NSObject>

- (void)credentialsUpdated:(PKPushCredentials *)credentials;
- (void)credentialsInvalidated;
- (void)incomingPushReceived:(PKPushPayload *)payload withCompletionHandler:(void (^)(void))completion;

@end

@interface RNTwilioVoice : RCTEventEmitter <RCTBridgeModule>

@end

@interface ViewController : UIViewController <PushKitEventDelegate>

- (instancetype)initWithToken:(NSString *)token;
- (void)setAccess:(NSString *)access;
- (void)configureCallKit:(NSDictionary *)params;

@end
