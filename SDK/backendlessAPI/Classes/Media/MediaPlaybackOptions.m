//
//  MediaPlaybackOptions.m
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

#import "MediaPlaybackOptions.h"
#import "DEBUG.h"
#import "Backendless.h"

@implementation MediaPlaybackOptions
#if TARGET_OS_IPHONE
-(id)init {
	if ( (self=[super init]) ) {
        _isLive = YES;
        _isRealTime = NO;
        _clientBufferMs = 0;
        _orientation = UIImageOrientationRight;
        _previewPanel = nil;
	}
	
	return self;
}

-(void)dealloc {
	
	[DebLog logN:@"DEALLOC MediaPlaybackOptions"];
	
	[super dealloc];
}

+(id)liveStream:(UIImageView *)view {
    
    MediaPlaybackOptions *instance = [MediaPlaybackOptions new];
    instance.previewPanel = view;
    
    return [instance autorelease];
}

+(id)recordStream:(UIImageView *)view {
    
    MediaPlaybackOptions *instance = [MediaPlaybackOptions new];
    instance.previewPanel = view;
    instance.isLive = NO;
    
    return [instance autorelease];
}

+(id)options:(BOOL)isLive orientation:(UIImageOrientation)orientation view:(UIImageView *)view {
    
    MediaPlaybackOptions *instance = [MediaPlaybackOptions new];
    instance.previewPanel = view;
    instance.isLive = isLive;
    instance.orientation = orientation;
    
    return [instance autorelease];  
}

-(NSString *)getServerURL {
#if TEST_MEDIA_INSTANCE
    return [backendless mediaServerUrl];
#else
    NSString *url = [NSString stringWithFormat:@"%@%@/_definst_", [backendless mediaServerUrl], _isLive?@"Live":@"Vod"];
    [DebLog log:@">>>>>>>>>>>>>>>>>> MediaPlaybackOptions -> getServerURL: %@", url];
    return url;
#endif
}
#endif
@end
