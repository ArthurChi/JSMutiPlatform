//
//  ViewController.m
//  JSMutiPlatform
//
//  Created by cjfire on 16/10/21.
//  Copyright © 2016年 cjfire. All rights reserved.
//

#import "ViewController.h"
#import "WebViewBridge.h"
#import "UIWebView+JSBridge.h"

@interface ViewController () <UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _webView.delegate = self;
    [_webView registBridgeAs:@"WebViewJavascriptBridge"];
    [_webView.bridge registMethod:@selector(abc) asJSName:@"abc" forTarget:self];
    [_webView.bridge registHandler:@"testObjcCallback" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"这里是native回调, 数据是%@", data);
        
        NSString* str = [NSString stringWithFormat:@"给你数据%@", data];
        responseCallback(str);
    }];
    
    NSString* path = [[NSBundle mainBundle] pathForResource:@"ExampleApp" ofType:@"html"];
    NSURL* url = [NSURL fileURLWithPath:path];
    NSURLRequest* req = [NSURLRequest requestWithURL:url];
    [_webView loadRequest:req];
}

- (void)abc {
    NSLog(@"~~~123");
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    return YES;
}

@end
