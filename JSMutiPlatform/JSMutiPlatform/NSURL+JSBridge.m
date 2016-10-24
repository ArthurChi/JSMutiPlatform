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

@implementation NSURL (JSBridge)

- (BOOL)isBridgeLoaded {
    return [self.scheme  isEqual: kBridgeScheme] && [self.host  isEqual: kBridgeLoaded];
}

@end
