//
//  FDMemLogger.m
//  HotlineSDK
//
//  Created by Hrishikesh on 14/04/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FCMemLogger.h"
#import "FCUtilities.h"
#import "FCVersionConstants.h"
#import "FCMacros.h"
#import "FCAPIClient.h"
#import "FCServiceRequest.h"
#import "FCNotificationHandler.h"
#import "FCSecureStore.h"

@interface FCMemLogger ()

@property (nonatomic, strong) NSMutableArray *logList;

@end

@implementation FCMemLogger

static NSString * const LOGGER_API = @"https://xp8jwcfqkf.execute-api.us-east-1.amazonaws.com/prod/error";

+(NSString*) getSessionId{
    static NSString *sessionId;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sessionId = [FCStringUtil generateUUID];
    });
    return sessionId;
}

-(id)init{
    self = [super init];
    if(self){
        _logList = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)addMessage:(NSString *) message{
    [self.logList addObject:message];
}

-(void)addMessage:(NSString*) message withMethodName:(NSString*) methodName{
    [self addMessage:[NSString stringWithFormat:@"%@ : %@", methodName, message]];
}

-(void)addErrorInfo:(NSDictionary*) dict withMethodName:(NSString*) methodName{
    [self addMessage:[NSString stringWithFormat:@"%@ : %@", methodName, dict]];
}

-(void)addErrorInfo:(NSDictionary*) dict{
    [self addMessage:[NSString stringWithFormat:@"Error Info : %@", dict]];
}

-(NSString *)getApplicationState {
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    if (state == UIApplicationStateActive){
        return @"Active";
    }else if(state == UIApplicationStateInactive){
        return @"Inactive";
    }else{
        return @"Background";
    }
    return @"";
}

-(NSString *)toString {
    
    NSString *pushNotifState = @"";
    NSString *appState = @"";
    
    if([NSThread isMainThread]) {
        appState = [self getApplicationState];
        pushNotifState = ([FCNotificationHandler areNotificationsEnabled]) ? @"Yes" : @"No";
    } else {
        __block NSString *temp_appState = @"";
        __block NSString *temp_pushNotifState = @"";
        dispatch_sync(dispatch_get_main_queue(), ^{
            temp_appState = [self getApplicationState];
            temp_pushNotifState = ([FCNotificationHandler areNotificationsEnabled]) ? @"Yes" : @"No";
        });
        appState = temp_appState;
        pushNotifState = temp_pushNotifState;
    }
    
    NSString *userAlias = [FCUtilities currentUserAlias];
    userAlias = userAlias ? userAlias : @"NIL";
    
    BOOL isUserRegistered =  [[FCSecureStore sharedInstance] boolValueForKey:HOTLINE_DEFAULTS_IS_USER_REGISTERED];
    NSString *sessionID = [self getUserSessionId];
    
    NSDictionary *additionalInfo = @{
                                     @"Device Model" : [FCUtilities deviceModelName],
                                     @"Application state" : appState,
                                     @"User alias" : userAlias,
                                     @"Push notification enabled" : pushNotifState,
                                     @"Time stamp" : [NSDate date],
                                     @"SDK Version" : FRESHCHAT_SDK_VERSION,
                                     @"App Name" : [FCUtilities appName],
                                     @"deviceIosMeta" : [FCUtilities deviceInfoProperties],
                                     @"Is user registered" : isUserRegistered ? @"YES" : @"NO",
                                     @"SessionID" : sessionID ? sessionID : @"NIL"
                                     };
    
    [self addErrorInfo:additionalInfo withMethodName:@"AdditionalInfo"];
    return [self.logList componentsJoinedByString:@"\n"];
}

-(NSString *)getUserSessionId{
    return [NSString stringWithFormat:@"%@_%@", [FCMemLogger getSessionId], [[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]*1000] stringValue]];
}

-(void)upload{
    
    if (self.logList.count == 0 || [FCUtilities isAccountDeleted]) return;
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:nil];
    NSURL *url = [NSURL URLWithString:LOGGER_API];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSString *log = [self toString];
    FDLog(@"***Memlogger*** Going to upload: \n %@" , log);
    request.HTTPMethod = HTTP_METHOD_POST;
    request.HTTPBody = [log dataUsingEncoding:NSUTF8StringEncoding];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error) {
            [self reset];
            FDLog(@"successfully uploaded log");
        }else{
            ALog(@"Failed  : %@",log);
            FDLog(@"Response %@", response);
        }
    }]resume];
}

-(void)reset{
    self.logList = [[NSMutableArray alloc]init];
}

+(void)sendMessage:(NSString *) message fromMethod:(NSString*) methodName{
    FCMemLogger *logger = [FCMemLogger new];
    [logger addMessage:message withMethodName:methodName];
    [logger upload];
}

@end