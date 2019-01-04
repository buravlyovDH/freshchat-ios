//
//  CategoryViewBehaviour.m
//  HotlineSDK
//
//  Created by Hrishikesh on 11/01/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FCLoadingViewBehaviour.h"
#import "FCFAQUtil.h"
#import "FCTagManager.h"
#import "FCLocalNotification.h"
#import "FCMacros.h"
#import "FCUtilities.h"
#import "FCBarButtonItem.h"
#import "FCLocalization.h"
#import "FCSearchViewController.h"
#import "FCControllerUtils.h"
#import "FCEmptyResultView.h"
#import "FCAutolayoutHelper.h"
#import "FCReachabilityManager.h"
#import "FCRemoteConfig.h"
#import "FCJWTAuthValidator.h"

@interface  FCLoadingViewBehaviour ()

@property (nonatomic, weak) UIViewController <HLLoadingViewBehaviourDelegate> *loadingViewDelegate;
@property (nonatomic, strong) FCTheme *theme;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) FCEmptyResultView *emptyResultView;
@property (nonatomic) enum SupportType solType;
@property (nonatomic) BOOL isWaitingForJWT;
@property (nonatomic, strong) NSTimer *loadingDismissTimer;

@end

@implementation FCLoadingViewBehaviour

-(instancetype) initWithViewController:(UIViewController <HLLoadingViewBehaviourDelegate> *) viewController withType:(enum SupportType)solType{
    self = [super init];
    if(self){
        self.loadingViewDelegate = viewController;
        self.theme = [FCTheme sharedInstance];
        self.solType = solType;
        self.isWaitingForJWT = FALSE;
    }
    return self;
}

-(void) load:(long)currentCount{
    if(currentCount == 0 ){
        [self addLoadingIndicator];
        [self updateResultsView:YES andCount:currentCount];
    }
}

-(void) unload{
    self.activityIndicator = nil;
    self.emptyResultView = nil;
    self.loadingViewDelegate = nil;
}

-(void)addLoadingIndicator{
    if(self.activityIndicator || self.loadingViewDelegate == nil){
        if(self.isWaitingForJWT){
            [self.activityIndicator removeFromSuperview];
        }
        else{
            return;
        }
    }
    UIView *view = self.loadingViewDelegate.view;
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityIndicator.translatesAutoresizingMaskIntoConstraints = false;
    [view insertSubview:self.activityIndicator aboveSubview:[self.loadingViewDelegate contentDisplayView]];
    self.activityIndicator.color = [[FCTheme sharedInstance] progressBarColor];
    [self.activityIndicator startAnimating];
    [FCAutolayoutHelper centerX:self.activityIndicator onView:view M:1 C:0];
    CGFloat multiplier = (self.isWaitingForJWT) ? 1.0 : 1.5;
    [FCAutolayoutHelper centerY:self.activityIndicator onView:view M:multiplier C:0];
}

-(FCEmptyResultView *)emptyResultView
{
    if (!_emptyResultView) {
        _emptyResultView = [[FCEmptyResultView alloc]initWithImage:[self.theme getImageWithKey:IMAGE_FAQ_ICON] withType:self.solType andText:@""];
        _emptyResultView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _emptyResultView;
}


-(void)removeLoadingIndicator{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.activityIndicator removeFromSuperview];
        self.activityIndicator = nil;
    });
}

-(void)updateResultsView:(BOOL)isLoading andCount:(long) count{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if(self.loadingViewDelegate == nil ) {
            return;
        }
        
        if(!isLoading || [FCUtilities isAccountDeleted]){
            if(!self.isWaitingForJWT) {
                [self removeLoadingIndicator];
            }
        }
        if(count == 0) {
            NSString *message;
            if([FCUtilities isAccountDeleted]){
                message = HLLocalizedString(LOC_ERROR_MESSAGE_ACCOUNT_NOT_ACTIVE_TEXT);
            }
            else if(isLoading){
                message = [self.loadingViewDelegate loadingText];
            }
            else if(![[FCReachabilityManager sharedInstance] isReachable]){
                message = HLLocalizedString(LOC_OFFLINE_INTERNET_MESSAGE);
            }
            else {
                message = [self.loadingViewDelegate emptyText];
            }
            
            if (self.isWaitingForJWT) {
                
                self.emptyResultView.emptyResultImage.image = nil;
                message = nil;
                self.activityIndicator.transform = CGAffineTransformMakeScale(1.7f, 1.7f);
                if([[FCJWTAuthValidator sharedInstance] canStartLoadingTimer]
                   && self.loadingDismissTimer == nil ){
                    self.loadingDismissTimer = [NSTimer scheduledTimerWithTimeInterval:([FCRemoteConfig sharedInstance].userAuthConfig.authTimeOutInterval / 1000 )
                                                                      target:self
                                                                    selector:@selector(dismissFreshchatViews)
                                                                    userInfo:nil
                                                                     repeats:NO];
                }
            }
            self.emptyResultView.emptyResultLabel.text = message;
            [self.loadingViewDelegate.view addSubview:self.emptyResultView];
            [FCAutolayoutHelper center:self.emptyResultView onView:self.loadingViewDelegate.view];
        }
        else{
            if (!self.isWaitingForJWT) {
                self.emptyResultView.frame = CGRectZero;
                [self.emptyResultView removeFromSuperview];
            }
        }
    });
}

- (void) dismissFreshchatViews{
    [[Freshchat sharedInstance] dismissFreshchatViews];
}

-(void) setJWTState:(BOOL) isAuthInProgress {
    self.isWaitingForJWT = isAuthInProgress;
}

-(void) showLoadingScreen {
    [self load:0];
}

-(void) hideLoadingScreen {
    [self updateResultsView:NO andCount:1];
    [self killTimer];
}

- (void)killTimer {
    [self.loadingDismissTimer invalidate];
    self.loadingDismissTimer = nil;
}

@end