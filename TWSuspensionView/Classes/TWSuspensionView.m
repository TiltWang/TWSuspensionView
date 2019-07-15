//
//  TWSuspensionView.m
//  TWSuspensionView
//
//  Created by Tilt on 2019/7/11.
//  Copyright © 2019 tilt. All rights reserved.
//

#import "TWSuspensionView.h"
#import "UIImage+TWSuspensionView.h"

#define TW_ISIPHONEX \
({BOOL isPhoneX = NO;\
if (@available(iOS 11.0, *)) {\
isPhoneX = [[UIApplication sharedApplication] delegate].window.safeAreaInsets.bottom > 0.0;\
}\
(isPhoneX);})

#pragma mark - Macros
//全局浮窗
static TWSuspensionView *suspensionView;
//浮窗宽度
static const CGFloat cFloatingWindowWidth = 60.0;
//默认缩放动画时间
static const NSTimeInterval cFloatingWindowPathAnimtiontDuration = 0.3;
//浮窗左右两边最小间距
static const CGFloat cFloatingWindowMargin = 20.0;
//红色浮窗隐藏视图宽度
static const CGFloat cFloatingWindowContentWidth = 160.0;
//默认动画时间
static const NSTimeInterval cFloatingWindowAnimtionDefaultDuration = 0.25;
//浮窗上下两边最小间距 非 iPhoneX
static const CGFloat cFloatingWindowTopBottomMargin = 64.0;
//浮窗上下两边最小间距 iPhoneX
static const CGFloat cFloatingWindowTopBottomMarginIphoneX = 86.0;

#pragma mark - *** 红色隐藏视图 ****
/// 视图右下红色隐藏视图,浮窗拖入消失
@interface TWSuspensionContentView : UIView
/**
 扩散效果
 */
- (void)spreadAnimation;
/**
 取消扩散效果
 */
- (void)cancelSpreadAnimation;
@end

#pragma mark - *** 震动器 ****
@interface TWSuspensionShakeManager : NSObject
/**
 震动器单例
 
 @return 震动器
 */
+ (instancetype)share;

/**
 震动方法
 */
- (void)shake;
@end

#pragma mark - *********************************** 转场动画视图 ******************************************
/// 转场扩散动画视图
@interface TWSuspensionAnimationView : UIView <CAAnimationDelegate>
@property (nonatomic, strong) UIImage *screenImage;
@end

@implementation TWSuspensionAnimationView {
    UIImageView *p_imageView;
    CAShapeLayer *p_shapeLayer;
    UIView *p_theView;
}
#pragma mark - public
/// 扩散动画
- (void)startAnimatingWithView:(UIView *)view fromRect:(CGRect)fromRect toRect:(CGRect)toRect {
    p_theView = view;
    
    p_shapeLayer = [CAShapeLayer layer];
    p_shapeLayer.path = [UIBezierPath bezierPathWithRoundedRect:fromRect cornerRadius:cFloatingWindowWidth * 0.5].CGPath;
    p_shapeLayer.fillColor = [UIColor lightGrayColor].CGColor;
    p_imageView.layer.mask = p_shapeLayer;
    
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"path"];
    anim.toValue = (__bridge id)[UIBezierPath bezierPathWithRoundedRect:toRect cornerRadius:cFloatingWindowWidth * 0.5].CGPath;
    anim.duration = cFloatingWindowPathAnimtiontDuration;
    anim.delegate = self;
    anim.fillMode = kCAFillModeForwards;
    anim.removedOnCompletion = NO;
    
    [p_shapeLayer addAnimation:anim forKey:@"TWSuspensionAnimation"];
}

#pragma mark system
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}

#pragma mark  private
- (void)setupUI {
    self.backgroundColor = [UIColor clearColor];
    p_imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    [self addSubview:p_imageView];
}
- (void)setScreenImage:(UIImage *)screenImage {
    p_imageView.image = screenImage;
}

#pragma mark - CAAnimationDelegate
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    p_theView.hidden = NO;
    [self removeFromSuperview];
}
@end

#pragma mark - ********************************** 转场工具类 ********************************************
@interface TWSuspensionAnimator : NSObject <UIViewControllerAnimatedTransitioning>
@property (nonatomic, assign) CGPoint currentFloatingCenter;
@property (nonatomic, assign) UINavigationControllerOperation operation;
@property (nonatomic, assign) BOOL isInteractive;
@end

@implementation TWSuspensionAnimator

#pragma mark  UIViewControllerAnimatedTransitioning
- (void)animateTransition:(nonnull id<UIViewControllerContextTransitioning>)transitionContext {
    UIView *containerView = transitionContext.containerView;
    
    if (_operation == UINavigationControllerOperationPush) {
        UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
        [containerView addSubview:toView];
        TWSuspensionAnimationView *animationV = [[TWSuspensionAnimationView alloc] initWithFrame:toView.bounds];
        UIGraphicsBeginImageContext(toView.bounds.size);
        [toView.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        animationV.screenImage = image;
        toView.hidden = YES;
        UIGraphicsEndImageContext();
        [containerView addSubview:animationV];
        [animationV startAnimatingWithView:toView fromRect:CGRectMake(_currentFloatingCenter.x, _currentFloatingCenter.y, cFloatingWindowWidth, cFloatingWindowWidth) toRect:toView.frame];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(cFloatingWindowPathAnimtiontDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [transitionContext completeTransition:YES];
        });
        
    }else if (_operation == UINavigationControllerOperationPop) {
        
        UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
        [containerView addSubview:toView];
        UIView *fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
        [containerView bringSubviewToFront:fromView];
        if (_isInteractive) {
            /// 可交互式动画
            [UIView animateWithDuration:0.3f animations:^{
                fromView.frame = CGRectOffset(fromView.frame, [UIScreen mainScreen].bounds.size.width, 0.f);
            } completion:^(BOOL finished) {
                [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
                if (!transitionContext.transitionWasCancelled) {
                    suspensionView.alpha = 1.f;
                }
            }];
            
        } else {
            /// 非可交互式动画
            TWSuspensionAnimationView *theView = [[TWSuspensionAnimationView alloc] initWithFrame:fromView.bounds];
            UIGraphicsBeginImageContext(fromView.bounds.size);
            [fromView.layer renderInContext:UIGraphicsGetCurrentContext()];
            UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
            theView.screenImage = image;
            UIGraphicsEndImageContext();
            CGRect fromRect = fromView.frame;
            fromView.frame = CGRectZero;
            [containerView addSubview:theView];
            [theView startAnimatingWithView:theView fromRect:fromRect toRect:CGRectMake(_currentFloatingCenter.x, _currentFloatingCenter.y, 60.f, 60.f)];
            [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
            suspensionView.alpha = 1.f;
        }
    }
}
- (NSTimeInterval)transitionDuration:(nullable id<UIViewControllerContextTransitioning>)transitionContext {
    return 1.0;
}
@end


#pragma mark - *********************************** 滑动pop适配器 ****************************************
@interface TWInteractiveTransition : UIPercentDrivenInteractiveTransition
@property (nonatomic, assign) BOOL isInteractive;
@property (nonatomic, assign) CGPoint curPoint;
- (void)transitionToViewController:(UIViewController *)toViewController;
@end

@implementation TWInteractiveTransition {
    __weak UIViewController *presentedViewController;
    BOOL shouldComplete;
    CGFloat transitionX;
}

- (void)dealloc {
    NSLog(@"%@ +++ %s",NSStringFromClass([self class]),__func__);
}

- (void)transitionToViewController:(UIViewController *)toViewController {
    presentedViewController = toViewController;
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
    toViewController.view.userInteractionEnabled = YES;
    [toViewController.view addGestureRecognizer:panGesture];
}

- (void)panAction:(UIPanGestureRecognizer *)gesture {
    UINavigationController *nav = (UINavigationController *)[UIApplication sharedApplication].keyWindow.rootViewController;
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            _isInteractive = YES;
            [nav popViewControllerAnimated:YES];
            break;
            
        case UIGestureRecognizerStateChanged: {
            //监听当前滑动的距离
            CGPoint transitionPoint = [gesture translationInView:presentedViewController.view];
            CGFloat ratio = transitionPoint.x/[UIScreen mainScreen].bounds.size.width;
            transitionX = transitionPoint.x;
            suspensionView.alpha = ratio;
            if (ratio >= 0.5) {
                shouldComplete = YES;
            } else {
                shouldComplete = NO;
            }
            [self updateInteractiveTransition:ratio];
        }
            break;
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            
            if (shouldComplete) {
                UIView *fromView = presentedViewController.view;
                TWSuspensionAnimationView *theView = [[TWSuspensionAnimationView alloc] initWithFrame:fromView.bounds];
                UIGraphicsBeginImageContext(fromView.bounds.size);
                [fromView.layer renderInContext:UIGraphicsGetCurrentContext()];
                UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
                theView.screenImage = image;
                UIGraphicsEndImageContext();
                CGRect fromRect = fromView.frame;
                fromView.frame = CGRectZero;
                [fromView.superview addSubview:theView];
                [theView startAnimatingWithView:theView fromRect:CGRectMake(transitionX, 0.f, fromRect.size.width, fromRect.size.height) toRect:CGRectMake(_curPoint.x, _curPoint.y, 60.f, 60.f)];
                [self finishInteractiveTransition];
                nav.delegate = nil;
            } else {
                suspensionView.alpha = 0.f;
                [self cancelInteractiveTransition];
            }
            _isInteractive = NO;
        }
            break;
        default:
            break;
    }
}
@end

#pragma mark - ************************************ 浮窗视图 ********************************************
@interface TWSuspensionView() <UINavigationControllerDelegate>
@end

@implementation TWSuspensionView {
    CGSize screenSize;
    CGPoint lastPointInSuperView;
    CGPoint lastPointInSelf;
    TWInteractiveTransition *weakInteractiveTransition;
    BOOL p_isShowing;
    UIViewController *p_containerVC;
    BOOL isShake;
}
//全局隐藏浮窗视图
static TWSuspensionContentView *suspensionContentView;

#pragma mark - publish
+ (void)showWithViewController:(UIViewController *)viewController {
    UINavigationController *nav = viewController.navigationController;
    if (!nav) {
        NSLog(@"展示浮窗必须添加到 NavigationController 管理的视图上!");
        return;
    }
    if (suspensionView && suspensionView->p_isShowing) {
        if (viewController == suspensionView->p_containerVC) {
            NSLog(@"当前控制器的浮窗已经添加了...");
            return;
        }
        NSLog(@"正在展示一个浮窗 - 视图: %@",suspensionView->p_containerVC);
        suspensionView->p_containerVC = nil;
    }
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CGFloat minY =  TW_ISIPHONEX ? cFloatingWindowTopBottomMarginIphoneX : cFloatingWindowTopBottomMargin;
        suspensionView = [[TWSuspensionView alloc] initWithFrame:CGRectMake(UIScreen.mainScreen.bounds.size.width - cFloatingWindowWidth - cFloatingWindowMargin, minY, cFloatingWindowWidth, cFloatingWindowWidth)];
        suspensionContentView = [[TWSuspensionContentView alloc] initWithFrame:CGRectMake(UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height, cFloatingWindowContentWidth, cFloatingWindowContentWidth)];
    });
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    if (!suspensionContentView.superview) {
        [keyWindow addSubview:suspensionContentView];
        [keyWindow bringSubviewToFront:suspensionContentView];
    }
    if (!suspensionView.superview) {
        [keyWindow addSubview:suspensionView];
        [keyWindow bringSubviewToFront:suspensionView];
    }
    
    suspensionView->p_containerVC = viewController;
    suspensionView->p_isShowing = YES;
    
    nav.delegate = suspensionView;
    [nav popViewControllerAnimated:YES];
}

+ (void)remove {
    UINavigationController *navi = suspensionView->p_containerVC.navigationController;
    navi.delegate = nil;
    suspensionView->weakInteractiveTransition = nil;
    suspensionView->p_containerVC = nil;
    [suspensionView removeFloatingWindow];
}

+ (BOOL)isShowingWithViewController:(UIViewController *)viewController {
    if (!suspensionView) {
        return NO;
    }
    if (suspensionView->p_containerVC != viewController) {
        return NO;
    }
    return suspensionView->p_isShowing;
}

#pragma mark - system
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    UITouch *touch = [touches anyObject];
    lastPointInSuperView = [touch locationInView:self.superview];
    lastPointInSelf = [touch locationInView:self];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    UITouch *touch = [touches anyObject];
    CGPoint curentPoint = [touch locationInView:self.superview];
    
    /// 展开 右下浮窗隐藏视图
    if (!CGPointEqualToPoint(lastPointInSuperView, curentPoint)) {
        /// 有移动才展开
        CGRect rect = CGRectMake(screenSize.width - cFloatingWindowContentWidth, screenSize.height - cFloatingWindowContentWidth, cFloatingWindowContentWidth, cFloatingWindowContentWidth);
        if (!CGRectEqualToRect(suspensionContentView.frame, rect)) {
            [UIView animateWithDuration:cFloatingWindowAnimtionDefaultDuration animations:^{
                suspensionContentView.frame = rect;
            }];
        }
    }
    
    /// 调整浮窗中心点
    CGFloat halfWidth = self.frame.size.width * 0.5;
    CGFloat halfHeight = self.frame.size.height * 0.5;
    CGFloat centerX = curentPoint.x + (halfWidth - lastPointInSelf.x);
    CGFloat centerY = curentPoint.y + (halfHeight - lastPointInSelf.y);
    CGFloat x = MIN(screenSize.width - halfWidth, MAX(centerX, halfWidth));
    CGFloat y = MIN(screenSize.height - halfHeight, MAX(centerY, halfHeight));
    self.center = CGPointMake(x,y);
    
    /// 震动
    CGFloat distance = sqrtf( (pow(self->screenSize.width - suspensionView.center.x,2) + pow(self->screenSize.height - suspensionView.center.y, 2)) );
    if (!isShake && (distance < (cFloatingWindowContentWidth - cFloatingWindowWidth * 0.5) ) ) {
        [[TWSuspensionShakeManager share] shake];
        isShake = YES;
        [suspensionContentView spreadAnimation];
    }else if (distance > (cFloatingWindowContentWidth - cFloatingWindowWidth * 0.5)) {
        isShake = NO;
        [suspensionContentView cancelSpreadAnimation];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    
    UITouch *touch = [touches anyObject];
    CGPoint currentPoint = [touch locationInView:self.superview];
    
    if (CGPointEqualToPoint(lastPointInSuperView, currentPoint)) {
        [self toContainerVC];
    }else{
        
        /// 收缩 右下浮窗隐藏视图
        [UIView animateWithDuration:cFloatingWindowAnimtionDefaultDuration animations:^{
            /// 浮窗在隐藏视图内部,移除浮窗
            CGFloat distance = sqrtf( (pow(self->screenSize.width - suspensionView.center.x,2) + pow(self->screenSize.height - suspensionView.center.y, 2)) );
            if (distance < (cFloatingWindowContentWidth - cFloatingWindowWidth * 0.5)) {
                [TWSuspensionView remove];
            }
            suspensionContentView.frame = CGRectMake(self->screenSize.width, self->screenSize.height, cFloatingWindowContentWidth, cFloatingWindowContentWidth);
        }];
        CGFloat left = currentPoint.x;
        CGFloat right = screenSize.width - currentPoint.x;
        
        CGFloat y = self.center.y;
        if (TW_ISIPHONEX) {
            y = MIN(screenSize.height - cFloatingWindowTopBottomMarginIphoneX, MAX(y, cFloatingWindowTopBottomMarginIphoneX));
        }else{
            y = MIN(screenSize.height - cFloatingWindowTopBottomMargin, MAX(y, cFloatingWindowTopBottomMargin));
        }
        if (left <= right) {
            [UIView animateWithDuration:cFloatingWindowAnimtionDefaultDuration animations:^{
                self.center = CGPointMake(cFloatingWindowMargin + self.bounds.size.width * 0.5, y);
            }];
        }else{
            [UIView animateWithDuration:cFloatingWindowAnimtionDefaultDuration animations:^{
                self.center = CGPointMake(self->screenSize.width - cFloatingWindowMargin - self.bounds.size.width * 0.5, y);
            }];
        }
    }
}

#pragma mark - private
- (void)setupUI {
    screenSize = UIScreen.mainScreen.bounds.size;
    self.backgroundColor = [UIColor clearColor];
    self.layer.contents = (__bridge id)[UIImage sus_imageNamed:@"WebView_Minimize_Float_IconHL"].CGImage;
}

- (void)toContainerVC {
    TWInteractiveTransition * interactiveTransition = [[TWInteractiveTransition alloc] init];
    weakInteractiveTransition = interactiveTransition;
    interactiveTransition.curPoint = self.frame.origin;
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    if (![rootVC isKindOfClass:[UINavigationController class]]) {
        NSLog(@"根控制器不是 UINavigationController");
        return;
    }
    UINavigationController *navi = (UINavigationController *)rootVC;
    navi.delegate = self;
    [interactiveTransition transitionToViewController:p_containerVC];
    [navi pushViewController:p_containerVC animated:YES];
}

- (void)removeFloatingWindow {
    [self removeFromSuperview];
    p_isShowing = NO;
}

#pragma mark - getter

#pragma mark - UINavigationControllerDelegate
- (nullable id <UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                            animationControllerForOperation:(UINavigationControllerOperation)operation
                                                         fromViewController:(UIViewController *)fromVC
                                                           toViewController:(UIViewController *)toVC {
    
    if ((operation == UINavigationControllerOperationPush && toVC != self->p_containerVC) || (operation == UINavigationControllerOperationPop && fromVC != self->p_containerVC) ) {
        return NULL;
    }
    
    if (operation == UINavigationControllerOperationPush) {
        self.alpha = 0.0;
    }
    TWSuspensionAnimator *floatingAnimator = [[TWSuspensionAnimator alloc] init];
    floatingAnimator.currentFloatingCenter = self.frame.origin;
    floatingAnimator.operation = operation;
    floatingAnimator.isInteractive = weakInteractiveTransition.isInteractive;
    return floatingAnimator;
}
- (nullable id <UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController
                                   interactionControllerForAnimationController:(id <UIViewControllerAnimatedTransitioning>) animationController {
    return weakInteractiveTransition.isInteractive ? weakInteractiveTransition : nil;
}
@end

#pragma mark - ******************************** 浮窗右下红色容器视图 **************************************

@implementation TWSuspensionContentView {
    CAShapeLayer *p_shapeLayer;
    CALayer *p_imageLayer;
    CATextLayer *p_textLayer;
    
    UIBezierPath *spreadPath;
    UIBezierPath *originPath;
    CABasicAnimation *imageLayerScaleAnim;
}
#pragma mark - public
- (void)spreadAnimation {
    if (!spreadPath) {
        spreadPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.frame.size.width, self.frame.size.height) radius:self.frame.size.width + 10 startAngle:-M_PI_2 endAngle:-M_PI clockwise:NO];
        [spreadPath addLineToPoint:CGPointMake(self.frame.size.width, self.frame.size.height)];
        [spreadPath closePath];
    }
    p_shapeLayer.path = spreadPath.CGPath;
    
    if (!imageLayerScaleAnim) {
        imageLayerScaleAnim = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        imageLayerScaleAnim.toValue = [NSNumber numberWithFloat:1.2];
        imageLayerScaleAnim.duration = 0.1;
        imageLayerScaleAnim.repeatCount = 1.0;
        imageLayerScaleAnim.removedOnCompletion = NO;
        imageLayerScaleAnim.fillMode = kCAFillModeForwards;
    }
    [p_imageLayer addAnimation:imageLayerScaleAnim forKey:@"imageLayerScale"];
}

- (void)cancelSpreadAnimation {
    if (!originPath) {
        originPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.frame.size.width, self.frame.size.height) radius:self.frame.size.width startAngle:-M_PI_2 endAngle:-M_PI clockwise:NO];
        [originPath addLineToPoint:CGPointMake(self.frame.size.width, self.frame.size.height)];
        [originPath closePath];
    }
    p_shapeLayer.path = originPath.CGPath;
    [p_imageLayer removeAnimationForKey:@"imageLayerScale"];
}

#pragma mark - system
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}
#pragma mark - private
- (void)setupUI {
    [self.layer addSublayer:self.shapeLayer];
    [self.layer addSublayer:self.imageLayer];
    [self.layer addSublayer:self.textLayer];
    CGFloat imageW = 50.0;
    p_imageLayer.frame = CGRectMake(0.5 * (self.frame.size.width - imageW), 0.5 * (self.frame.size.height - imageW), imageW, imageW);
    p_textLayer.frame = CGRectMake(p_imageLayer.frame.origin.x, CGRectGetMaxY(p_imageLayer.frame) + 3.0, p_imageLayer.frame.size.width, 20);
}

#pragma mark - getter
- (CAShapeLayer *)shapeLayer {
    if(!p_shapeLayer){
        p_shapeLayer = [CAShapeLayer layer];
        UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.frame.size.width, self.frame.size.height) radius:self.frame.size.width startAngle:-M_PI_2 endAngle:-M_PI clockwise:NO];
        [path addLineToPoint:CGPointMake(self.frame.size.width, self.frame.size.height)];
        [path closePath];
        p_shapeLayer.path = path.CGPath;
        p_shapeLayer.fillColor = [UIColor colorWithRed:206/255.0 green:85/255.0 blue:85/255.0 alpha:1].CGColor;;
    }
    return p_shapeLayer;
}
- (CALayer *)imageLayer {
    if(!p_imageLayer){
        p_imageLayer = [[CALayer alloc] init];
        p_imageLayer.contents = (__bridge id)[UIImage sus_imageNamed:@"WebView_Minimize_Corner_Icon_remove"].CGImage;
    }
    return p_imageLayer;
}
- (CATextLayer *)textLayer {
    if(!p_textLayer){
        p_textLayer = [[CATextLayer alloc] init];
        p_textLayer.string = @"取消浮窗";
        p_textLayer.fontSize = 12.0;
        p_textLayer.contentsScale = [UIScreen mainScreen].scale;
        p_textLayer.foregroundColor = [UIColor colorWithRed:234.f/255.0 green:160.f/255.0 blue:160.f/255.0 alpha:1].CGColor;
    }
    return p_textLayer;
}
@end


#pragma mark - ************************************ 震动器 **********************************************
@implementation TWSuspensionShakeManager {
    API_AVAILABLE(ios(10.0))
    UIImpactFeedbackGenerator *_generator;
}
/// 单例对象
static TWSuspensionShakeManager *p_floatingShakeManager;
#pragma mark - public
- (void)shake {
    if (@available(iOS 10.0, *)) {
        [_generator prepare];
        [_generator impactOccurred];
    }
}
#pragma mark - system
- (instancetype)init {
    if (self = [super init]) {
        if (@available(iOS 10.0, *)) {
            /// ios10 以上才可震动
            _generator = [[UIImpactFeedbackGenerator alloc] initWithStyle: UIImpactFeedbackStyleLight];
        }
    }
    return self;
}
#pragma mark - 单例对象
+ (instancetype)share {
    if (!p_floatingShakeManager) {
        p_floatingShakeManager = [[self alloc] init];
    }
    return p_floatingShakeManager;
}
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    if (!p_floatingShakeManager) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            p_floatingShakeManager = [super allocWithZone:zone];
        });
    }
    return p_floatingShakeManager;
}
- (id)copyWithZone:(NSZone *)zone{
    return p_floatingShakeManager;
}
- (id)mutableCopyWithZone:(NSZone *)zone{
    return p_floatingShakeManager;
}
@end
