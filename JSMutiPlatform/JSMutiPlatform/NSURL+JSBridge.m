//
//  NSURL+JSBridge.m
//  JSMutiPlatform
//
//  Created by cjfire on 16/10/24.
//  Copyright © 2016年 cjfire. All rights reserved.
//

#import "NSURL+JSBridge.h"
#define kBridgeScheme @"wvjbscheme"
#define kBridgeLoaded @"__BRIDGE_LOADED__"
#define kBridgeMessage @"__WVJB_QUEUE_MESSAGE__"

@implementation NSURL (JSBridge)

- (BOOL)isBridgeLoaded {
    return [self.scheme  isEqualToString:kBridgeScheme] && [self.host  isEqualToString:kBridgeLoaded];
}

- (BOOL)isFetchQueueQueryMsg {
    return [self.scheme isEqualToString:kBridgeScheme] && [self.host isEqualToString:kBridgeMessage];
}

@end
