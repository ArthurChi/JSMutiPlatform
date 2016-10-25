//
//  UIWebView+JSBridge.m
//  JSMutiPlatform
//
//  Created by cjfire on 16/10/25.
//  Copyright © 2016年 cjfire. All rights reserved.
//

#import "UIWebView+JSBridge.h"
#import "WebViewBridge.h"
#import <objc/runtime.h>

static NSString* webViewBridge = @"webViewBridge";
static NSString* alias = @"alias";

@interface UIWebView()

@property (nonatomic, strong, readwrite) WebViewBridge* bridge;
@property (nonatomic, copy, readwrite) NSString* alias;

@end

@implementation UIWebView (JSBridge)
@dynamic bridge;
@dynamic alias;

- (void)setBridge:(WebViewBridge *)bridge {
    objc_setAssociatedObject(self, &webViewBridge, bridge, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (WebViewBridge*)bridge {
    return objc_getAssociatedObject(self, &webViewBridge);
}

- (void)setAlias:(NSString *)alias {
    objc_setAssociatedObject(self, &alias, alias, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString*)alias {
    return objc_getAssociatedObject(self, &alias);
}

- (void)registBridgeAs:(NSString*)alias {
    NSAssert(self.delegate != nil, @"delegate mustn't be nil");
    
    self.bridge = [[WebViewBridge alloc] initWith:self];
    self.alias = alias;
}

@end
