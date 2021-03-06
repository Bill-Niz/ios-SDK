//
//  MediaPublisher.m
//  backendlessAPI
/*
 * *********************************************************************************************************************
 *
 *  BACKENDLESS.COM CONFIDENTIAL
 *
 *  ********************************************************************************************************************
 *
 *  Copyright 2012 BACKENDLESS.COM. All Rights Reserved.
 *
 *  NOTICE: All information contained herein is, and remains the property of Backendless.com and its suppliers,
 *  if any. The intellectual and technical concepts contained herein are proprietary to Backendless.com and its
 *  suppliers and may be covered by U.S. and Foreign Patents, patents in process, and are protected by trade secret
 *  or copyright law. Dissemination of this information or reproduction of this material is strictly forbidden
 *  unless prior written permission is obtained from Backendless.com.
 *
 *  ********************************************************************************************************************
 */

#import "MediaPublisher.h"
#import "DEBUG.h"
#import "MediaPublishOptions.h"
#import "Backendless.h"

#if TARGET_OS_IPHONE
#import "BroadcastStreamClient.h"

static NSString *OPTIONS_IS_ABSENT = @"Options is absent. You shpuld set 'options' property";
static NSString *STREAM_IS_ABSENT = @"Stream is absent. You should invoke 'connect' method";

@interface MediaPublisher () <MPIMediaStreamEvent, IMediaStreamerDelegate> {
    
    BroadcastStreamClient *_stream;
}

@end

@implementation MediaPublisher

-(id)init {
	
    if ( (self=[super init]) ) {
        _stream = nil;
        _options = nil;
        _streamPath = nil;
        _tubeName = nil;
        _streamName = nil;
	}
	
	return self;
}

-(void)dealloc {
	
	[DebLog logN:@"DEALLOC MediaPublisher"];
    
    [self disconnect];
    
    [_options release];
    [_streamPath release];
    [_tubeName release];
    [_streamName release];
 	
	[super dealloc];
}

#pragma mark -
#pragma mark Private Methods

-(BOOL)wrongOptions {
    
    if (!_options) {
        [self streamConnectFailed:self code:-1 description:OPTIONS_IS_ABSENT];
        return YES;
    }
    
    if (!_stream) {
        [self streamConnectFailed:self code:-2 description:STREAM_IS_ABSENT];
        return YES;
    }
        
    return NO;
}

#pragma mark -
#pragma mark Public Methods

-(void)switchCameras {
    
    if ([self wrongOptions])
        return;
    
    [_stream switchCameras];
}

-(void)setVideoBitrate:(uint)bitRate {
    
    if ([self wrongOptions])
        return;
    
    _options.videoBitrate = bitRate;
    [_stream setVideoBitrate:bitRate];
}

-(void)setAudioBitrate:(uint)bitRate {
    
    if ([self wrongOptions])
        return;
    
    _options.audioBitrate = bitRate;
    [_stream setAudioBitrate:bitRate];
}

-(AVCaptureSession *)getCaptureSession {
    return [_stream getCaptureSession];
}

-(BOOL)sendImage:(CGImageRef)image timestamp:(int64_t)timestamp {
    return [_stream sendImage:image timestamp:timestamp];
}

-(BOOL)sendFrame:(CVPixelBufferRef)pixelBuffer timestamp:(int)timestamp {
    return [_stream sendFrame:pixelBuffer timestamp:timestamp];
}

-(BOOL)sendSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    return [_stream sendSampleBuffer:sampleBuffer];
}

-(void)sendMetadata:(NSDictionary *)data {
    [_stream sendMetadata:data];
}

-(void)sendMetadata:(NSDictionary *)data event:(NSString *)event {
    [_stream sendMetadata:data event:event];
}

-(NSString *)operationType {
    
    switch (_options.publishType) {
        case PUBLISH_LIVE:
            return @"publishLive";
        default:
            return @"publishRecorded";
    }
}

-(NSString *)streamType {
     
    switch (_options.publishType) {
        case PUBLISH_RECORD:
            return @"live-record";
        case PUBLISH_APPEND:
            return @"append";
        default:
            return @"live";
    }
}

-(NSArray *)parameters {
    
#if TEST_MEDIA_INSTANCE
    return nil;
#else
    
    id identity = backendless.userService.currentUser ? backendless.userService.currentUser.getUserToken : nil;
    if (!identity) identity = [NSNull null];
    
    id tube = _tubeName ? _tubeName : [NSNull null];
    
    NSArray *param = [NSArray arrayWithObjects:backendless.appID, backendless.versionNum, identity, tube, [self operationType], [self streamType], nil];
    
    [DebLog log:@"MediaPublisher -> parameters:%@", param];
    
    return param;
#endif
}

#pragma mark -
#pragma mark IMediaStream Methods

-(MPMediaStreamState)currentState {
    return [self wrongOptions] ? CONN_DISCONNECTED : (MPMediaStreamState)_stream.state;
}

-(void)connect {

    if (!_options) {
        [self streamConnectFailed:self code:-1 description:OPTIONS_IS_ABSENT];
        return;
    }
    
    if (_stream)
        [_stream disconnect];
    
    [DebLog log:@"MediaPublisher -> connect: content = %d", _options.content];
    
    switch (_options.content) {
        
        case AUDIO_AND_VIDEO: {
            _stream = [[BroadcastStreamClient alloc] init:_streamPath resolution:(MPVideoResolution)_options.resolution];
            [_stream switchCameras];
            [_stream setPreviewLayer:_options.previewPanel];
            break;
        }
            
        case ONLY_VIDEO: {
            _stream = [[BroadcastStreamClient alloc] initOnlyVideo:_streamPath resolution:(MPVideoResolution)_options.resolution];
            [_stream switchCameras];
            [_stream setPreviewLayer:_options.previewPanel];
            break;
        }
            
        case ONLY_AUDIO: {
            _stream = [[BroadcastStreamClient alloc] initOnlyAudio:_streamPath];
            break;
        }
            
        case CUSTOM_VIDEO: {
            _stream = [[BroadcastStreamClient alloc] init:_streamPath resolution:(MPVideoResolution)_options.resolution];
            if (_options.resolution == RESOLUTION_CUSTOM)
                [_stream setVideoCustom:_options.fps width:_options.width height:_options.height];
            else
                [_stream setVideoMode:VIDEO_CUSTOM];
            [_stream setAudioMode:AUDIO_OFF];
            [_stream setPreviewLayer:_options.previewPanel];
            break;
        }
            
        case AUDIO_AND_CUSTOM_VIDEO: {
            _stream = [[BroadcastStreamClient alloc] init:_streamPath resolution:(MPVideoResolution)_options.resolution];
            if (_options.resolution == RESOLUTION_CUSTOM)
                [_stream setVideoCustom:_options.fps width:_options.width height:_options.height];
            else
                [_stream setVideoMode:VIDEO_CUSTOM];
            [_stream setAudioMode:AUDIO_ON];
            [_stream setPreviewLayer:_options.previewPanel];
            break;
        }
           
        default:
            return;
    }
    
#if IS_MEDIA_ENCODER
    _stream.videoCodecId = _options.videoCodecId;
    _stream.audioCodecId = _options.audioCodecId;
#endif
    
    [_stream setVideoOrientation:_options.orientation];
    
    if (_options.videoBitrate)
        [_stream setVideoBitrate:_options.videoBitrate];
    
    if (_options.audioBitrate)
        [_stream setAudioBitrate:_options.audioBitrate];
    
    _stream.parameters = [self parameters];
    
    _stream.delegate = self;
    [_stream stream:_streamName publishType:(MPMediaPublishType)_options.publishType];
}

-(void)start {
    
    if ([self wrongOptions])
        return;
    
    [_stream start];
}

-(void)pause {
    
    if ([self wrongOptions])
        return;
    
    [_stream pause];
}

-(void)resume {
    
    if ([self wrongOptions])
        return;
    
    [_stream resume];
}

-(void)stop {
    
    if ([self wrongOptions])
        return;
    
    [_stream stop];
}

-(void)disconnect {
    
    _delegate = nil;
    
    [_stream disconnect];
    _stream = nil;
}

#pragma mark -
#pragma mark IMediaStreamerDelegate Methods

-(void)streamStateChanged:(id)sender state:(int)state description:(NSString *)description {
    if ([_delegate respondsToSelector:@selector(streamStateChanged:state:description:)])
        [_delegate streamStateChanged:sender state:state description:description];
}

-(void)streamConnectFailed:(id)sender code:(int)code description:(NSString *)description {
    if ([_delegate respondsToSelector:@selector(streamConnectFailed:code:description:)])
        [_delegate streamConnectFailed:sender code:code description:description];
}

#pragma mark -
#pragma mark IMediaStreamEvent Methods

-(void)stateChanged:(id)sender state:(MPMediaStreamState)state description:(NSString *)description {
    
    [DebLog log:@"MediaPublisher <IMediaStreamEvent> stateChangedEvent: %d = %@", (int)state, description];
    
    switch (state) {
            
        case CONN_DISCONNECTED: {
            
            _stream = nil;
            
            break;
        }
            
        case CONN_CONNECTED: {
            
            if (![description isEqualToString:MP_RTMP_CLIENT_IS_CONNECTED])
                break;
            
            [self start];
            
            break;
        }
#if 0
        case STREAM_CREATED: {
            
            if ([description isEqualToString:MP_NETSTREAM_PUBLISH_START])
                break;
            
            [self streamConnectFailed:sender code:(int)state description:description];
            
            return;
        }
#endif
        case STREAM_PAUSED: {
            
            break;
        }
            
        case STREAM_PLAYING: {
            
            break;
        }
            
        default:
            break;
    }
    
    [self streamStateChanged:self state:(int)state description:description];
}

-(void)connectFailed:(id)sender code:(int)code description:(NSString *)description {
    
   [DebLog log:@"MediaPublisher <IMediaStreamEvent> connectFailedEvent: %d = %@\n", code, description];
    
    _stream = nil;
    
    [self streamConnectFailed:self code:code description:description];
}
@end

#else

@implementation MediaPublisher
@end
#endif

