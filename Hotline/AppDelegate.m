//
//  AppDelegate.m
//  Hotline
//
//  Created by AravinthChandran on 9/7/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "AppDelegate.h"
#import "HotlineSDK/Hotline.h"
#import "ViewController.h"

@interface AppDelegate ()

@property (nonatomic, strong)UIViewController *rootController;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self hotlineIntegration];
    [self registerAppForNotifications];
    [self setupRootController];
    if ([[Hotline sharedInstance]isHotlineNotification:launchOptions]) {
        [[Hotline sharedInstance]handleRemoteNotification:launchOptions andAppstate:application.applicationState];
    }

    NSLog(@"launchoptions :%@", launchOptions);
    return YES;
}

-(void)setupRootController{
    
    BOOL isTabViewPreferred = YES;

    if (isTabViewPreferred) {
        UIViewController* mainView=[self.window rootViewController];
        [mainView setTitle:@"Order"];
        UIViewController* solutionsViewController=[[Hotline sharedInstance] getSolutionsControllerForEmbed];
        [solutionsViewController setTitle:@"FAQs"];
        UITabBarController* tabBarController=[[UITabBarController alloc] init];
        UIViewController* channelsView=[[Hotline sharedInstance] getConversationsControllerForEmbed];
        [channelsView setTitle:@"Channels"];
        [tabBarController setViewControllers:@[mainView,solutionsViewController,channelsView]];
        [tabBarController.tabBar setClipsToBounds:NO];
        [tabBarController.tabBar setTintColor:[UIColor colorWithRed:(0x33/0xFF) green:(0x36/0xFF) blue:(0x45/0xFF) alpha:1.0]];
        [tabBarController.tabBar setBarStyle:UIBarStyleDefault];
        [self.window setRootViewController:tabBarController];
        [self.window makeKeyAndVisible];
    }
}

-(void)hotlineIntegration{
    HotlineConfig *config = [[HotlineConfig alloc]initWithDomain:@"hline.pagekite.me"
                                                       withAppID:@"0e611e03-572a-4c49-82a9-e63ae6a3758e"
                                                       andAppKey:@"be346b63-59d7-4cbc-9a47-f3a01e35f093"];
    
    config.voiceMessagingEnabled = YES;
    config.pictureMessagingEnabled = YES;
    HotlineUser *user = [HotlineUser sharedInstance];
    user.userName = @"Sid";
    user.emailAddress = @"sid@freshdesk.com";
    user.phoneNumber = @"9898989898";
    [[Hotline sharedInstance]initWithConfig:config andUser:user];
    [[Hotline sharedInstance]setCustomUserPropertyForKey:@"CustomerID" withValue:@"10231023"];
    
    NSLog(@"Unread messages count :%ld", [[Hotline sharedInstance]unreadCount]);
    [[Hotline sharedInstance]unreadCountWithCompletion:^(NSInteger count) {
        NSLog(@"Unread count (Async) : %d", (int)count);
    }];
}

-(void)registerAppForNotifications{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }else{
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes: (UIRemoteNotificationTypeNewsstandContentAvailability| UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    }
}

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken {
    NSLog(@"Registered Device Token  %@", devToken);
    NSLog(@"is app registered for notifications :: %d" , [[UIApplication sharedApplication] isRegisteredForRemoteNotifications]);
    [[Hotline sharedInstance] addDeviceToken:devToken];
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"Failed to register remote notification  %@", error);
}

- (void) application:(UIApplication *)app didReceiveRemoteNotification:(NSDictionary *)info{
    if ([[Hotline sharedInstance]isHotlineNotification:info]) {
        [[Hotline sharedInstance]handleRemoteNotification:info andAppstate:app.applicationState];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application{
    NSInteger unreadCount = [[Hotline sharedInstance]unreadCount];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:unreadCount];
}

/* 
 supported deep link URLs to test:
 hotline://?launch=shoes
 hotline://?launch=cloths
 */
-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation{
    if ([url.scheme isEqualToString:@"hotline"]) {

        if ([url.query isEqualToString:@"launch=shoes"]) {
            NSLog(@"Lauch shoes screen");
        }
        
        if ([url.query isEqualToString:@"launch=cloths"]) {
            NSLog(@"Launch cloths screen");
        }

    }
    
    return YES;
}

@end