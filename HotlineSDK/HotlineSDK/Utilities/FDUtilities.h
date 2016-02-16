//
//  FDUtilities.h
//  FreshdeskSDK
//
//  Created by balaji on 15/05/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#ifndef FreshdeskSDK_FDUtilities_h
#define FreshdeskSDK_FDUtilities_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FDUtilities : NSObject

+(NSString *)getUserAlias;
+(NSString *)generateUUID;
+(void)storeUserAlias:(NSString *)alias;
+(BOOL)isUserRegistered;
+(BOOL)isValidEmail:(NSString *)email;

+(NSString *)base64EncodedStringFromString:(NSString *)string;
+(NSString *)sanitizeStringForUTF8:(NSString *)string;
+(NSString *)sanitizeStringForNewLineCharacter:(NSString *)string;
+(NSString *)replaceSpecialCharacters:(NSString *)term with:(NSString *)replaceString;
+(UIImage *)imageWithColor:(UIColor *)color;
+(NSString*)stringRepresentationForDate:(NSDate*) date;
+(NSString *) getKeyForObject:(NSObject *) object;
+(NSString *)getAdID;
+(NSString *)getBaseURL;
+(NSString *)generateOfflineMessageAlias;
+(NSDictionary *)deviceInfoProperties;
+(void)setActivityIndicator:(BOOL)isVisible;

+(void) AlertView:(NSString *)alertviewstring FromModule:(NSString *)pModule;
+(void) PostNotificationWithName :(NSString *) notName withObject: (id) object;
+(BOOL) isPoweredByHidden;
+(NSNumber *)getLastUpdatedTimeForKey:(NSString *)key;

@end

#endif