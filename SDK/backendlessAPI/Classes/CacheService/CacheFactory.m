//
//  CacheFactory.m
//  backendlessAPI
/*
 * *********************************************************************************************************************
 *
 *  BACKENDLESS.COM CONFIDENTIAL
 *
 *  ********************************************************************************************************************
 *
 *  Copyright 2014 BACKENDLESS.COM. All Rights Reserved.
 *
 *  NOTICE: All information contained herein is, and remains the property of Backendless.com and its suppliers,
 *  if any. The intellectual and technical concepts contained herein are proprietary to Backendless.com and its
 *  suppliers and may be covered by U.S. and Foreign Patents, patents in process, and are protected by trade secret
 *  or copyright law. Dissemination of this information or reproduction of this material is strictly forbidden
 *  unless prior written permission is obtained from Backendless.com.
 *
 *  ********************************************************************************************************************
 */

#import "CacheFactory.h"
#include "Backendless.h"

#define FAULT_NO_ENTITY_TYPE [Fault fault:@"Entity type is not valid" faultCode:@"0000"]

@interface CacheFactory () {
    NSString *_key;
    Class _entityClass;
}
@end

@implementation CacheFactory

-(id)init {
	if ( (self=[super init]) ) {
        _key = @"DEFAULT_KEY";
        _entityClass = nil;
	}
	
	return self;
}

-(id)init:(NSString *)key type:(Class)entityClass {
	if ( (self=[super init]) ) {
        _key = [key retain];
        _entityClass = [entityClass retain];
	}
	
	return self;
}

+(id <ICacheService>)create:(NSString *)key {
    return [[CacheFactory alloc] init:key type:nil];
}

+(id <ICacheService>)create:(NSString *)key type:(Class)entityClass {
    return [[CacheFactory alloc] init:key type:entityClass];
}

-(void)dealloc {
	
	[DebLog logN:@"DEALLOC CacheFactory"];
    
    [_key release];
    [_entityClass release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Private Methods

-(Fault *)entityValidation:(id)entity {
    return (_entityClass && ![(NSObject *)entity isKindOfClass:_entityClass]) ? [backendless throwFault:FAULT_NO_ENTITY_TYPE] : nil;
}

#pragma mark -
#pragma mark ICacheService Methods

// sync methods with fault return (as exception)

-(id)put:(id)entity {
    return [self put:entity timeToLive:0];
}

-(id)put:(id)entity timeToLive:(int)seconds {
    
    Fault *fault = [self entityValidation:entity];
    return fault? fault : [backendless.cache put:_key object:entity timeToLive:seconds];
}

-(id)get {
    return [backendless.cache get:_key];
}

-(NSNumber *)contains {
    return [backendless.cache contains:_key];
}

-(id)expireIn:(int)seconds {
    return [backendless.cache expireIn:_key timeToLive:seconds];
}

-(id)expireAt:(NSDate *)timestamp {
    return [backendless.cache expireAt:_key timestamp:timestamp];
}

-(id)remove {
    return [backendless.cache remove:_key];
}

// sync methods with fault option

-(BOOL)put:(id)entity fault:(Fault **)fault {
    return [self put:entity timeToLive:0 fault:fault];
}

-(BOOL)put:(id)entity timeToLive:(int)seconds fault:(Fault **)fault {
    
    Fault *noValid = [self entityValidation:entity];
    if (noValid) {
        if (fault)(*fault) = noValid;
        return NO;
    }
    
    return [backendless.cache put:_key object:entity timeToLive:seconds fault:fault];
}

-(id)get:(Fault **)fault {
    return [backendless.cache get:_key fault:fault];
}

-(NSNumber *)contains:(Fault **)fault {
    return [backendless.cache contains:_key fault:fault];
}

-(BOOL)expireIn:(int)seconds fault:(Fault **)fault {
    return [backendless.cache expireIn:_key timeToLive:seconds fault:fault];
}

-(BOOL)expireAt:(NSDate *)timestamp fault:(Fault **)fault {
    return [backendless.cache expireAt:_key timestamp:timestamp fault:fault];
}

-(BOOL)remove:(Fault **)fault {
    return [backendless.cache remove:_key fault:fault];
}

// async methods with responder

-(void)put:(id)entity responder:(id<IResponder>)responder {
    [self put:entity timeToLive:0 responder:responder];
}

-(void)put:(id)entity timeToLive:(int)seconds responder:(id<IResponder>)responder {
    Fault *noValid = [self entityValidation:entity];
    noValid ? [responder errorHandler:noValid] : [backendless.cache put:_key object:entity timeToLive:seconds responder:responder];
}

-(void)getToResponder:(id<IResponder>)responder {
    [backendless.cache get:_key responder:responder];
}

-(void)containsToResponder:(id<IResponder>)responder {
    [backendless.cache contains:_key responder:responder];
}

-(void)expireIn:(int)seconds responder:(id<IResponder>)responder {
    [backendless.cache expireIn:_key timeToLive:seconds responder:responder];
}

-(void)expireAt:(NSDate *)timestamp responder:(id<IResponder>)responder {
    [backendless.cache expireAt:_key timestamp:timestamp responder:responder];
}

-(void)removeToResponder:(id<IResponder>)responder {
    [backendless.cache remove:_key responder:responder];
}

// async methods with block-based callback

-(void)put:(id)entity response:(void (^)(id))responseBlock error:(void (^)(Fault *))errorBlock {
    [self put:entity timeToLive:0 response:responseBlock error:errorBlock];
}

-(void)put:(id)entity timeToLive:(int)seconds response:(void (^)(id))responseBlock error:(void (^)(Fault *))errorBlock {
    [self put:entity timeToLive:seconds responder:[ResponderBlocksContext responderBlocksContext:responseBlock error:errorBlock]];
}

-(void)get:(void (^)(id))responseBlock error:(void (^)(Fault *))errorBlock {
    [backendless.cache get:_key response:responseBlock error:errorBlock];
}

-(void)contains:(void (^)(NSNumber *))responseBlock error:(void (^)(Fault *))errorBlock {
    [backendless.cache contains:_key response:responseBlock error:errorBlock];
}

-(void)expireIn:(int)seconds response:(void (^)(id))responseBlock error:(void (^)(Fault *))errorBlock {
    [backendless.cache expireIn:_key timeToLive:seconds response:responseBlock error:errorBlock];
}

-(void)expireAt:(NSDate *)timestamp response:(void (^)(id))responseBlock error:(void (^)(Fault *))errorBlock {
    [backendless.cache expireAt:_key timestamp:timestamp response:responseBlock error:errorBlock];
}

-(void)remove:(void (^)(id))responseBlock error:(void (^)(Fault *))errorBlock {
    [backendless.cache remove:_key response:responseBlock error:errorBlock];
}

@end
