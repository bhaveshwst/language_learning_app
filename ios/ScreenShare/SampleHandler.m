#import "SampleHandler.h"
#import <ZegoExpressEngine/ZegoExpressDefines.h>
#import <ZegoExpressEngine/ZegoExpressEventHandler.h>

@interface SampleHandler () <ZegoReplayKitExtHandler>
@end

@implementation SampleHandler

- (void)broadcastStartedWithSetupInfo:(NSDictionary<NSString *,NSObject *> *)setupInfo {
  [ZegoReplayKitExt.sharedInstance setupWithDelegate:self];
}

- (void)broadcastPaused {
}

- (void)broadcastResumed {
}

- (void)broadcastFinished {
  [ZegoReplayKitExt.sharedInstance finished];
}

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer
                   withType:(RPSampleBufferType)sampleBufferType {
  [ZegoReplayKitExt.sharedInstance sendSampleBuffer:sampleBuffer withType:sampleBufferType];
}

- (void)broadcastFinished:(ZegoReplayKitExt *)broadcast
                   reason:(ZegoReplayKitExtReason)reason {
  switch (reason) {
    case ZegoReplayKitExtReasonHostStop: {
      NSDictionary *userInfo = @{
        NSLocalizedDescriptionKey : @"Host app stopped screen capture"
      };
      NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                           code:0
                                       userInfo:userInfo];
      [self finishBroadcastWithError:error];
      break;
    }
    case ZegoReplayKitExtReasonConnectFail: {
      NSDictionary *userInfo = @{
        NSLocalizedDescriptionKey :
            @"Connect host app failed; need startScreenCapture in host app"
      };
      NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                           code:0
                                       userInfo:userInfo];
      [self finishBroadcastWithError:error];
      break;
    }
    case ZegoReplayKitExtReasonDisconnect: {
      NSDictionary *userInfo = @{
        NSLocalizedDescriptionKey : @"Disconnected from host app"
      };
      NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                           code:0
                                       userInfo:userInfo];
      [self finishBroadcastWithError:error];
      break;
    }
  }
}

@end
