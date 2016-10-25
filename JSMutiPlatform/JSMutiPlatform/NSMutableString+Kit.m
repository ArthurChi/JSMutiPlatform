//
//  NSMutableString+Kit.m
//  JSMutiPlatform
//
//  Created by cjfire on 16/10/25.
//  Copyright © 2016年 cjfire. All rights reserved.
//

#import "NSMutableString+Kit.h"

@implementation NSMutableString (Kit)

-(void)replaceOccurrencesOfString:(NSString*)string withString:(NSString*)replacement {
    [self replaceOccurrencesOfString:string withString:replacement options:0 range:NSMakeRange(0, self.length)];
}

@end
