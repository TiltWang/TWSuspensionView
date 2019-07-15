//
//  UIImage+TWSuspensionView.m
//  TWSuspensionView
//
//  Created by Tilt on 2019/7/11.
//  Copyright © 2019 tilt. All rights reserved.
//

#import "UIImage+TWSuspensionView.h"
#import "NSBundle+TWSuspensionView.h"

@implementation UIImage (TWSuspensionView)

+ (UIImage *)sus_imageNamed:(NSString *)name {
    return [UIImage imageNamed:name inBundle:[NSBundle sus_Bundle] compatibleWithTraitCollection:nil];
}

@end
