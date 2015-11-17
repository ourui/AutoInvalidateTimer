//
//  NSTimer+FuckRetainTimer.m
//  Demo
//
//  Created by wangrui on 11/17/15.
//  Copyright © 2015 wangrui. All rights reserved.
//

#import "NSTimer+FuckRetainTimer.h"
#import <objc/runtime.h>
#import <libkern/OSAtomic.h>

@interface NSObject (FuckRetainTimerTarget)

@property(nonatomic,strong)NSMutableDictionary *fk_targets;
@end

@implementation NSObject (FuckRetainTimerTarget)

- (void)setFk_targets:(NSMutableDictionary *)fk_targets{
    objc_setAssociatedObject(self, @selector(fk_targets), fk_targets, OBJC_ASSOCIATION_RETAIN);
}

- (NSMutableDictionary *)fk_targets {
    return objc_getAssociatedObject(self, _cmd);
}

@end

@class FKTimerTarget;
@interface FKTimerInnerObject : NSObject

@property(nonatomic,weak)FKTimerTarget *outerTarget;
@end

@interface FKTimerTarget : NSObject

@property(nonatomic,weak)id target;
@property(nonatomic)SEL selector;
@property(nonatomic,strong)NSTimer *referenceTimer;
@property(nonatomic,strong)FKTimerInnerObject *innerTimerRetainObject;

- (id)initWithTarget:(id)target selector:(nonnull SEL)sel;

@end

static OSSpinLock _lock = OS_SPINLOCK_INIT;

@implementation FKTimerTarget

- (void)dealloc {
    [self.referenceTimer invalidate];
    self.referenceTimer = nil;
}

- (id)initWithTarget:(id)target selector:(nonnull SEL)sel {
    
    self = [super init];
    
    if (self) {
        
        self.target = target;
        self.selector = sel;
        
        self.innerTimerRetainObject = [FKTimerInnerObject new];
        self.innerTimerRetainObject.outerTarget = self;
        
    }
    
    return self;
}


- (void)fk_doForwordTimerAction:(id)sender {
    
    if (_target && _selector) {

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [_target performSelector:_selector withObject:sender];
#pragma clang diagnostic pop
    }
}

@end


@implementation FKTimerInnerObject

- (void)fk_timerAction:(id)sender {
    if (self.outerTarget) {
        [self.outerTarget fk_doForwordTimerAction:sender];
    }
}

@end

@implementation NSTimer (FuckRetainTimer)

- (void)setFk_watchedDeallocObject:(id)fk_watchedDeallocObject {
    
    if (fk_watchedDeallocObject != self.fk_watchedDeallocObject) {
        
        OSSpinLockLock(&_lock);
        
        NSMutableDictionary *targets = [self.fk_watchedDeallocObject fk_targets];
        FKTimerTarget *target = [targets objectForKey:[NSString stringWithFormat:@"%p",self]];
        
        if (target) {
            [targets removeObjectForKey:[NSString stringWithFormat:@"%p",self]];
            
            NSMutableDictionary *targets = [fk_watchedDeallocObject fk_targets];
            
            if (!targets) {
                [fk_watchedDeallocObject setFk_targets:[NSMutableDictionary dictionary]];
                targets = [fk_watchedDeallocObject fk_targets];
            }
            
            [targets setObject:target forKey:[NSString stringWithFormat:@"%p",self]];
            
            objc_setAssociatedObject(self, @selector(fk_watchedDeallocObject), fk_watchedDeallocObject, OBJC_ASSOCIATION_ASSIGN);
        }
        else {
            objc_setAssociatedObject(self, @selector(fk_watchedDeallocObject), fk_watchedDeallocObject, OBJC_ASSOCIATION_ASSIGN);
        }
        
        OSSpinLockUnlock(&_lock);
    }
}

- (id)fk_watchedDeallocObject {
    return objc_getAssociatedObject(self, _cmd);
}

+ (void)attatchTarget:(FKTimerTarget *)fk_taget toObject:(id)obj forTimer:(NSTimer *)timer{
    
    NSAssert(![fk_taget isKindOfClass:[NSTimer class]], @"Target Can't Be A NSTimer");
    
    OSSpinLockLock(&_lock);
    
    NSMutableDictionary *targets = [obj fk_targets];
    
    if (!targets) {
        [obj setFk_targets:[NSMutableDictionary dictionary]];
        targets = [obj fk_targets];
    }
    
    [targets setObject:fk_taget forKey:[NSString stringWithFormat:@"%p",timer]];
    
    OSSpinLockUnlock(&_lock);
    
    timer.fk_watchedDeallocObject = obj;
}

+ (NSTimer *)fk_timerWithTimeInterval:(NSTimeInterval)ti
                               target:(id)aTarget
                             selector:(SEL)aSelector
                             userInfo:(nullable id)userInfo
                              repeats:(BOOL)yesOrNo
{
    
    FKTimerTarget *fk_target = [[FKTimerTarget alloc] initWithTarget:aTarget selector:aSelector];
    
    NSTimer *timer = [NSTimer timerWithTimeInterval:ti
                                             target:fk_target.innerTimerRetainObject
                                           selector:@selector(fk_timerAction:)
                                           userInfo:userInfo
                                            repeats:yesOrNo];
    fk_target.referenceTimer = timer;
    [self attatchTarget:fk_target toObject:aTarget forTimer:timer];

    return timer;
}

+ (NSTimer *)fk_scheduledTimerWithTimeInterval:(NSTimeInterval)ti
                                        target:(id)aTarget
                                      selector:(SEL)aSelector
                                      userInfo:(nullable id)userInfo
                                       repeats:(BOOL)yesOrNo
{
    FKTimerTarget *fk_target = [[FKTimerTarget alloc] initWithTarget:aTarget selector:aSelector];
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:ti
                                                      target:fk_target.innerTimerRetainObject
                                                    selector:@selector(fk_timerAction:)
                                                    userInfo:userInfo
                                                     repeats:yesOrNo];
    
    fk_target.referenceTimer = timer;
    [self attatchTarget:fk_target toObject:aTarget forTimer:timer];
    
    return timer;
}

+ (NSTimer *)fk_scheduledTimerWithTimeInterval:(NSTimeInterval)inTimeInterval
                                         block:(void (^)(NSTimer *timer))inBlock
                                       repeats:(BOOL)inRepeats
{
    NSParameterAssert(inBlock != nil);
    return [self fk_scheduledTimerWithTimeInterval:inTimeInterval
                                            target:self
                                          selector:@selector(fk_executeBlockFromTimer:)
                                          userInfo:[inBlock copy]
                                           repeats:inRepeats];
}

+ (NSTimer *)fk_timerWithTimeInterval:(NSTimeInterval)inTimeInterval
                                block:(void (^)(NSTimer *timer))inBlock
                              repeats:(BOOL)inRepeats
{
    NSParameterAssert(inBlock != nil);
    return [self fk_timerWithTimeInterval:inTimeInterval
                                   target:self
                                 selector:@selector(fk_executeBlockFromTimer:)
                                 userInfo:[inBlock copy]
                                  repeats:inRepeats];
}

+ (void)fk_executeBlockFromTimer:(NSTimer *)aTimer {
    void (^block)(NSTimer *) = [aTimer userInfo];
    if (block) block(aTimer);
}

@end
