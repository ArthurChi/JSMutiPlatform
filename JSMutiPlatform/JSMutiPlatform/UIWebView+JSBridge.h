//
//  UIWebView+JSBridge.h
//  JSMutiPlatform
//
//  Created by cjfire on 16/10/25.
//  Copyright © 2016年 cjfire. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WebViewBridge;

@interface UIWebView (JSBridge)

@property (nonatomic, strong, readonly) WebViewBridge* bridge;
@property (nonatomic, copy, readonly) NSString* alias;

/**
 *  should set webview's delegate before the invocation of this method
 *
 *  @param alias  alias
 */
- (void)registBridgeAs:(NSString*)alias;

@end
