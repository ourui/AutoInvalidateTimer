//
//  ViewController.m
//  Demo
//
//  Created by wangrui on 11/17/15.
//  Copyright © 2015 wangrui. All rights reserved.
//

#import "ViewController.h"
#import "NSTimer+FuckRetainTimer.h"

@interface ViewController ()

@property(nonatomic,strong)NSTimer *timer;
@end

@implementation ViewController

- (void)dealloc {
    NSLog(@"timer will auto invalid");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
  
    if (self.usingTimer) {
        
        //eg1.
        NSTimer *timer = [NSTimer fk_scheduledTimerWithTimeInterval:0.5 block:^(NSTimer * _Nonnull timer) {
            
            NSLog(@"Block time ++");
            
        } repeats:YES];
        
        timer.fk_watchedDeallocObject = self;
        
        //eg2.
       [NSTimer fk_scheduledTimerWithTimeInterval:.5
                                           target:self
                                         selector:@selector(time:)
                                         userInfo:nil
                                          repeats:YES];
        
        
        //eg3.
        NSTimer *timer2 = [NSTimer fk_scheduledTimerWithTimeInterval:.5
                                                              target:self.class
                                                            selector:@selector(time:)
                                                            userInfo:nil
                                                             repeats:YES];
        timer2.fk_watchedDeallocObject = self;
    }
}

- (IBAction)dosth:(id)sender {
    
    ViewController *vc = [ViewController new];
    vc.usingTimer = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)time:(id)sender {
    NSLog(@"time ++");
}

+ (void)time:(id)sender {
    NSLog(@"class time ++");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
