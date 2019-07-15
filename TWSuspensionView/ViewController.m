//
//  ViewController.m
//  TWSuspensionView
//
//  Created by Tilt on 2019/7/11.
//  Copyright © 2019 tilt. All rights reserved.
//

#import "ViewController.h"
#import "TestViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:((float)arc4random_uniform(256) / 255.0) green:((float)arc4random_uniform(256) / 255.0) blue:((float)arc4random_uniform(256) / 255.0) alpha:1.0];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    TestViewController *vc = [[TestViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
//    NSLog(@"尺寸--%@", NSStringFromCGRect(self.view.frame));
}


@end
