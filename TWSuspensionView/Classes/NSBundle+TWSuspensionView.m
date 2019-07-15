//
//  NSBundle+TWSuspensionView.m
//  TWSuspensionView
//
//  Created by Tilt on 2019/7/11.
//  Copyright © 2019 tilt. All rights reserved.
//

#import "NSBundle+TWSuspensionView.h"

@implementation NSBundle (TWSuspensionView)

+ (NSBundle *)sus_Bundle {
    static NSBundle *sus_Bundle = nil;
    if (!sus_Bundle) {
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"TWSuspensionView" ofType:@"bundle"];
        sus_Bundle = [NSBundle bundleWithPath:bundlePath];
    }
    return sus_Bundle;
}

@end
