//
//  cPlaybackOperation.h
//  playsoundObjectiveC
//
//  Created by DE4ME on 04.10.2022.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@interface cPlaybackOperation: NSOperation

@property (readonly) NSURL* url;
@property (nullable) NSString* output;
@property (nullable) NSString* decoder;

+ (instancetype)playbackOperationWithURL:(NSURL*)url output:(NSString* _Nullable)output decoder:(NSString* _Nullable)decoder;
- (instancetype)initWithURL:(NSURL*)url output:(NSString* _Nullable)output decoder:(NSString* _Nullable)decoder;

@end

NS_ASSUME_NONNULL_END
