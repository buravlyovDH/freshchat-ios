//
//  HLMessageServices.h
//  HotlineSDK
//
//  Created by user on 03/11/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HLChannel.h"

@interface HLMessageServices : NSObject

// fetches channel list, updates existing channels including hidden channels
-(NSURLSessionDataTask *)fetchAllChannels:(void (^)(NSArray<HLChannel *> *channels, NSError *error))handler;

@end