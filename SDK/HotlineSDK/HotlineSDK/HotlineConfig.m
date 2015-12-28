//
//  HotlineConfig.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 12/12/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Hotline.h"


@implementation HotlineConfig

-(instancetype)initWithDomain:(NSString *)domain withAppID:(NSString *)appID andAppKey:(NSString *)appKey{
    self = [super init];
    if (self) {
        self.domain = domain;
        self.appID = appID;
        self.appKey = appKey;
    }
    return self;
}

@end