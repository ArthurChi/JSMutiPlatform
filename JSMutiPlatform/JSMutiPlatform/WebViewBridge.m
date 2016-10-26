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
#import "NSMutableString+Kit.h"
#import <JavaScriptCore/JavaScriptCore.h>

@interface WebViewBridge() <UIWebViewDelegate>

@property (nonatomic, readwrite, weak) UIWebView* webView;
@property (nonatomic, strong) NSObject<UIWebViewDelegate>* target;
@property (nonatomic, strong) NSMutableDictionary* invocations;
@property (nonatomic, copy, readwrite) NSString* alias;
@property (nonatomic, strong) NSMutableDictionary* handlers;
@property (nonatomic, strong) NSMutableDictionary* responseCallbacks;

@end

@implementation WebViewBridge {
    long _uniqueId;
}

- (NSMutableDictionary *)invocations {
    if (!_invocations) {
        _invocations = [NSMutableDictionary dictionary];
    }
    
    return _invocations;
}

- (NSMutableDictionary*)handlers {
    if (!_handlers) {
        _handlers = [NSMutableDictionary dictionary];
    }
    
    return _handlers;
}

- (NSMutableDictionary *)responseCallbacks {
    if (!_responseCallbacks) {
        _responseCallbacks = [NSMutableDictionary dictionary];
    }
    
    return _responseCallbacks;
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

- (void)registHandler:(NSString*)handlerName handler:(WVJBHandler)handler {
    self.handlers[handlerName] = [handler copy];
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

- (NSDictionary*)deserializeMessage:(NSString*)messageJSON {
    
    NSArray* msgs = [NSJSONSerialization JSONObjectWithData:[messageJSON dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
    return msgs.firstObject;
}

- (NSString*)serializeMessage:(id)message {
    
    NSMutableString* messageJSON = [NSMutableString string];
    [messageJSON appendString:[[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:message options:0 error:nil] encoding:NSUTF8StringEncoding]];
    
    [messageJSON replaceOccurrencesOfString:@"\\" withString:@"\\\\"];
    [messageJSON replaceOccurrencesOfString:@"\"" withString:@"\\\""];
    [messageJSON replaceOccurrencesOfString:@"\'" withString:@"\\\'"];
    [messageJSON replaceOccurrencesOfString:@"\n" withString:@"\\n"];
    [messageJSON replaceOccurrencesOfString:@"\r" withString:@"\\r"];
    [messageJSON replaceOccurrencesOfString:@"\f" withString:@"\\f"];
    [messageJSON replaceOccurrencesOfString:@"\u2028" withString:@"\\u2028"];
    [messageJSON replaceOccurrencesOfString:@"\u2029" withString:@"\\u2029"];
    
    return messageJSON;
}

- (void)sendMessage:(NSDictionary*)message {
    
    NSString* messageInJson = [self serializeMessage:message];
    NSString* js = [NSString stringWithFormat:@"%@._handleMessageFromObjC('%@');", _alias, messageInJson];
    [_webView stringByEvaluatingJavaScriptFromString:js];
}

- (void)sendData:(id)data responseCallback:(WVJBResponseCallback)responseCallback handlerName:(NSString*)handlerName {
    NSMutableDictionary* message = [NSMutableDictionary dictionary];
    
    if (data) {
        message[@"data"] = data;
    }
    
    if (responseCallback) {
        NSString* callbackId = [NSString stringWithFormat:@"objc_cb_%ld", ++_uniqueId];
        self.responseCallbacks[callbackId] = [responseCallback copy];
        message[@"callbackId"] = callbackId;
    }
    
    if (handlerName) {
        message[@"handlerName"] = handlerName;
    }
    [self sendMessage:message];
}

// UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    NSLog(@"%@", request.URL.absoluteString);
    
    if (_webView == webView) {
        
        if ([request.URL isBridgeLoaded]) {
            [self injectJS];
        } else if ([request.URL isFetchQueueQueryMsg]) {
            NSString* messageJSON = [webView stringByEvaluatingJavaScriptFromString:[self fetchQueueJS]];
            
            NSDictionary* msgObj = [self deserializeMessage:messageJSON];
            
            if (msgObj[@"callName"]) {
                NSString* key = msgObj[@"callName"];
                NSInvocation* invocation = _invocations[key];
                [invocation invoke];
            } else if (msgObj[@"callbackId"]) {
                
                NSString* callbackId = msgObj[@"callbackId"];
                if (msgObj[@"handlerName"]) {
                    WVJBHandler handler = self.handlers[msgObj[@"handlerName"]];
                    
                    WVJBResponseCallback responseCallback = ^(id responseData) {
                        
                        if (!responseData) {
                            responseData = [NSNull null];
                        }
                        
                        NSDictionary* msg = @{@"responseId":callbackId, @"responseData":responseData};
                        [self sendMessage:msg];
                    };
                    
                    handler(msgObj[@"data"], responseCallback);
                }
                
            } else if (msgObj[@"responseId"]) {
                NSString* responseId = msgObj[@"responseId"];
                WVJBResponseCallback responseCallback = _responseCallbacks[responseId];
                responseCallback(msgObj[@"responseData"]);
                [self.responseCallbacks removeObjectForKey:responseId];
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