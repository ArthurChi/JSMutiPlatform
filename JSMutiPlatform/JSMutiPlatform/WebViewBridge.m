//
//  WebViewBridge.m
//  JSMutiPlatform
//
//  Created by cjfire on 16/10/21.
//  Copyright © 2016年 cjfire. All rights reserved.
//

#import "WebViewBridge.h"
#import <objc/runtime.h>
#import "NSURL+JSBridge.h"

@interface WebViewBridge() <UIWebViewDelegate>

@property(nonatomic, readwrite, weak) UIWebView* webView;
@property(nonatomic, strong) NSObject<UIWebViewDelegate>* target;
@property(nonatomic, strong) NSMutableDictionary* invocations;
@property (nonatomic, copy, readwrite) NSString* alias;

@end

@implementation WebViewBridge

- (NSMutableDictionary *)invocations {
    if (_invocations == nil) {
        _invocations = [NSMutableDictionary dictionary];
    }
    
    return _invocations;
}

- (instancetype) initWith:(UIWebView*)webView alias:(NSString*) alias {
    
    NSAssert(webView.delegate != nil, @"webview's delegate is nil");
    
    _target = webView.delegate;
    webView.delegate = self;
    _webView = webView;
    _alias = alias;
    
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

- (void)registMethod:(SEL)selector asJSName:(NSString*)jsName forTarget:(NSObject*)target {
    
    NSMethodSignature* methodSign = [[target class] instanceMethodSignatureForSelector:selector];
    NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:methodSign];
    self.invocations[jsName] = invocation;
    invocation.target = target;
    invocation.selector = selector;
}

#pragma mark - private API

- (void)injectJS {
    
    [_webView stringByEvaluatingJavaScriptFromString:[self pageLoadedJS]];
}

- (NSString*)fetchQueueJS {
    return [NSString stringWithFormat:@"%@._fetchQueue()", _alias];
}

- (NSString*)pageLoadedJS {
    
    NSString* path = [[NSBundle mainBundle] pathForResource:@"injectJs" ofType:@"js"];
    NSString* strjs = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    
    NSMutableString* pageLoadedJS = [NSMutableString string];
    [pageLoadedJS appendString:@"(function() {"];
    [pageLoadedJS appendFormat:@"if (window.%@) { return; }", _alias];
    [pageLoadedJS appendString:strjs];
    
    NSMutableDictionary* bridgeObj = [NSMutableDictionary dictionary];
    bridgeObj[@"registerHandler"] = @"registerHandler";
    bridgeObj[@"callHandler"] = @"callHandler";
    bridgeObj[@"disableJavscriptAlertBoxSafetyTimeout"] = @"disableJavscriptAlertBoxSafetyTimeout";
    bridgeObj[@"_fetchQueue"] = @"_fetchQueue";
    bridgeObj[@"_handleMessageFromObjC"] = @"_handleMessageFromObjC";
    
    for (NSString* key in _invocations.allKeys) {
        
        [pageLoadedJS appendFormat:@"function %@() { ", key];
        [pageLoadedJS appendString:@"var funName = functionName(arguments.callee.toString());"];
        [pageLoadedJS appendString:@"var message = {'callName':funName, 'argus':arguments};"];
        [pageLoadedJS appendString:@"sendMessageQueue.push(message);"];
        [pageLoadedJS appendString:@"messagingIframe.src = CUSTOM_PROTOCOL_SCHEME + '://' + QUEUE_HAS_MESSAGE; }"];
        bridgeObj[key] = key;
    }

    NSMutableString* bridgeObjJSON = [[NSMutableString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:bridgeObj options:0 error:nil] encoding:NSUTF8StringEncoding];
    
    [bridgeObjJSON replaceOccurrencesOfString:@";" withString:@"," options:0 range:NSMakeRange(0, bridgeObjJSON.length)];
    [bridgeObjJSON replaceOccurrencesOfString:@"\"" withString:@"" options:0 range:NSMakeRange(0, bridgeObjJSON.length)];
    
    [pageLoadedJS appendFormat:@"window.%@ =  %@ ;", _alias, bridgeObjJSON];
    
    [pageLoadedJS appendString:@"setTimeout(_callWVJBCallbacks, 0);"];
    [pageLoadedJS appendString:@"function _callWVJBCallbacks() { "];
    [pageLoadedJS appendString:@"var callbacks = window.WVJBCallbacks;"];
    [pageLoadedJS appendString:@"delete window.WVJBCallbacks;"];
    [pageLoadedJS appendString:@"for (var i=0; i<callbacks.length; i++) {"];
    [pageLoadedJS appendFormat:@"callbacks[i](%@);", _alias];
    [pageLoadedJS appendString:@"}}"];
    
    [pageLoadedJS appendString:@"})();"];
    
    return pageLoadedJS;
}

// UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    NSLog(@"%@", request.URL.absoluteString);
    
    if (_webView == webView) {
        
        if ([request.URL isBridgeLoaded]) {
            [self injectJS];
        } else if ([request.URL isFetchQueueQueryMsg]) {
            NSString* messageJSON = [webView stringByEvaluatingJavaScriptFromString:[self fetchQueueJS]];
            
            NSArray* json = [NSJSONSerialization JSONObjectWithData:[messageJSON dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
            
            for (NSDictionary* obj in json) {
                
                NSString* key = obj[@"callName"];
                NSInvocation* invocation = _invocations[key];
                [invocation invoke];
            }
        }
        
        SEL webViewShouldLoadReqSel = @selector(webView:shouldStartLoadWithRequest:navigationType:);
        
        if ([_target respondsToSelector:webViewShouldLoadReqSel]) {
            return [_target webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
        }
    }
    
    return YES;
}

@end