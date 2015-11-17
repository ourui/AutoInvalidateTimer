//
//  NSTimer+FuckRetainTimer.h
//  Demo
//
//  Created by wangrui on 11/17/15.
//  Copyright © 2015 wangrui. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSTimer (FuckRetainTimer)

/**
 *  fk_watchedDeallocObject: 设置一个对象,该对象delloc时timer会停止并释放
 *  必须用下面api产生的timer才会起作用
 *
 *  It works only using the timers created by below apis
 */
@property(nonatomic,assign)id fk_watchedDeallocObject;


/**
 *  下面两个api默认以 aTarget 为fk_watchedDeallocObject, 不需要再次设置. 如果aTarget
 *  为Class则需要设置
 */

/**
 *  reture a timer that not retain the target, and it will atuo invalid and release while target dealloc.
 */
+ (NSTimer *)fk_timerWithTimeInterval:(NSTimeInterval)ti
                               target:(id)aTarget
                             selector:(SEL)aSelector
                             userInfo:(nullable id)userInfo
                              repeats:(BOOL)yesOrNo;

/**
 *  auto fire
 */
+ (NSTimer *)fk_scheduledTimerWithTimeInterval:(NSTimeInterval)ti
                                        target:(id)aTarget
                                      selector:(SEL)aSelector
                                      userInfo:(nullable id)userInfo
                                       repeats:(BOOL)yesOrNo;

/**
 *  下面两个api默认有block回掉,需要单独设置fk_watchedDeallocObject,否则timer可能停止不掉
 */
+ (NSTimer *)fk_scheduledTimerWithTimeInterval:(NSTimeInterval)inTimeInterval
                                         block:(void (^)(NSTimer *timer))inBlock
                                       repeats:(BOOL)inRepeats;

/**
 *  auto fire
 */
+ (NSTimer *)fk_timerWithTimeInterval:(NSTimeInterval)inTimeInterval
                                block:(void (^)(NSTimer *timer))inBlock
                              repeats:(BOOL)inRepeats;

@end

NS_ASSUME_NONNULL_END
