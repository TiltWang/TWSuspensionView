//
//  TestViewController.m
//  TWSuspensionView
//
//  Created by Tilt on 2019/7/11.
//  Copyright © 2019 tilt. All rights reserved.
//

#import "TestViewController.h"
#import "TWSuspensionView.h"

@interface TestViewController ()

@end

@implementation TestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:((float)arc4random_uniform(256) / 255.0) green:((float)arc4random_uniform(256) / 255.0) blue:((float)arc4random_uniform(256) / 255.0) alpha:1.0];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [TWSuspensionView showWithViewController:self];
}


@end
