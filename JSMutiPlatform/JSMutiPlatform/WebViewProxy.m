//
//  WebViewProxy.m
//  JSMutiPlatform
//
//  Created by cjfire on 16/10/21.
//  Copyright © 2016年 cjfire. All rights reserved.
//

#import "WebViewProxy.h"
#import <objc/runtime.h>
#import "NSURL+JSBridge.h"

@interface WebViewProxy() <UIWebViewDelegate>

@property(nonatomic, readwrite, strong) UIWebView* webView;
@property(nonatomic, strong) NSObject<UIWebViewDelegate>* target;

@end

@implementation WebViewProxy

- (instancetype) initWith:(UIWebView*)webView {
    
    NSAssert(webView.delegate != nil, @"webview's delegate is nil");
    
    _target = webView.delegate;
    webView.delegate = self;
    _webView = webView;
    
    return self;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    
    unsigned methodCount = 0;
    Method* methods = class_copyMethodList([self class], &methodCount);
    
    for (int index = 0; index < methodCount; index ++) {
        
        Method method = methods[index];
        SEL methodSelector = method_getName(method);
        
        if (methodSelector == aSelector) {
            return YES;
        }
    }
    
    return NO;
}

// UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    NSLog(@"%@", request.URL.absoluteString);
    
    if (_webView == webView) {
        
        if ([request.URL isBridgeLoaded]) {
            NSString* path = [[NSBundle mainBundle] pathForResource:@"injectJs" ofType:@"js"];
            NSString* strjs = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
            [webView stringByEvaluatingJavaScriptFromString:strjs];
        }
        
        SEL webViewShouldLoadReqSel = @selector(webView:shouldStartLoadWithRequest:navigationType:);
        
        if ([_target respondsToSelector:webViewShouldLoadReqSel]) {
            return [_target webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
        }
    }
    
    return YES;
}

@end