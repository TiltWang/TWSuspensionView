//
//  TWSuspensionView.h
//  TWSuspensionView
//
//  Created by Tilt on 2019/7/11.
//  Copyright © 2019 tilt. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TWSuspensionView : UIView

/**
 展示浮窗
 */
+ (void)showWithViewController:(UIViewController *)viewController;

/**
 移除浮窗
 */
+ (void)remove;

/**
 是否正在展示浮窗
 */
+ (BOOL)isShowingWithViewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
