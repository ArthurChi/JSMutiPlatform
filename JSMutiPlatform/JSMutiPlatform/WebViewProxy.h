//
//  WebViewProxy.h
//  JSMutiPlatform
//
//  Created by cjfire on 16/10/21.
//  Copyright © 2016年 cjfire. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebViewProxy : NSProxy

@property (nonatomic, readonly) UIWebView* webView;

/**
 *  webview's delegate must defined before invoke this muthod
 *
 *  @param webView webView
 *
 *  @return webview's proxy
 */
- (instancetype) initWith:(UIWebView*)webView;

@end
