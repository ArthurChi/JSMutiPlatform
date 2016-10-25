//
//  WebViewBridge.h
//  JSMutiPlatform
//
//  Created by cjfire on 16/10/21.
//  Copyright © 2016年 cjfire. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebViewBridge : NSProxy

@property (nonatomic, readonly, weak) UIWebView* webView;
@property (nonatomic, copy, readonly) NSString* alias;

/**
 *  webview's delegate must defined before invoke this muthod
 *
 *  @param webView webView
 *
 *  @return webview's proxy
 */
- (instancetype) initWith:(UIWebView*)webView alias:(NSString*) alias;

- (void)registMethod:(SEL)selector asJSName:(NSString*)jsName forTarget:(NSObject*)target;

@end
