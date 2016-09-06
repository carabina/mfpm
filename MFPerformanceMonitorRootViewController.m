//
//  MFPerformanceMonitorRootViewController.m
//  MakeFriends
//
//  Created by Vic on 25/8/2016.
//
//

#import "MFPerformanceMonitorRootViewController.h"
#import "MFPerformanceMonitorViewController.h"
#import "MFPerformanceMonitorManager.h"
#import "MFPerformanceModel.h"

#if _INTERNAL_MFPM_ENABLED

@interface MFPerformanceMonitorRootViewController ()<UIAlertViewDelegate>

@property (nonatomic, weak) UIView *performanceView;
@property (nonatomic, weak) UIImageView *menuImageView;
@property (nonatomic, weak) UIButton *recordButton;
@property (nonatomic, weak) UIButton *chartButton;
@property (nonatomic, weak) UIButton *saveButton;

@end

@implementation MFPerformanceMonitorRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self inits];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    _performanceView.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 168, [UIScreen mainScreen].bounds.size.height - 42 - 50, 168, 42);
    _menuImageView.frame = CGRectMake(4, 5, 28, 32);
    _recordButton.frame = CGRectMake(48, 5, 32, 32);
    _chartButton.frame = CGRectMake(88, 5, 32, 32);
    _saveButton.frame = CGRectMake(128, 5, 32, 32);

}

- (void)inits
{
    [self initViews];
}

- (void)initViews
{
    self.view.backgroundColor = [UIColor clearColor];
    UIView *performanceView = [UIView new];
    performanceView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:0.8];
    [self.view addSubview:performanceView];
    _performanceView = performanceView;
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [performanceView addGestureRecognizer:panGesture];
    
    UIImageView *menuImageView = [UIImageView new];
    [performanceView addSubview:menuImageView];
    _menuImageView = menuImageView;
    menuImageView.image = [UIImage imageNamed:@"mf_performance_monitor_menu"];
    
    UIButton *recordButton = [UIButton new];
    [performanceView addSubview:recordButton];
    _recordButton = recordButton;
    [recordButton addTarget:self action:@selector(onTapRecord:) forControlEvents:UIControlEventTouchUpInside];
    [recordButton setBackgroundImage:[UIImage imageNamed:@"mf_performance_monitor_stop"] forState:UIControlStateNormal];
    
    UIButton *chartButton = [UIButton new];
    [performanceView addSubview:chartButton];
    _chartButton = chartButton;
    [chartButton addTarget:self action:@selector(onTapChart:) forControlEvents:UIControlEventTouchUpInside];
    [chartButton setBackgroundImage:[UIImage imageNamed:@"mf_performance_monitor_chart"] forState:UIControlStateNormal];
    
    UIButton *saveButton = [UIButton new];
    [performanceView addSubview:saveButton];
    _saveButton = saveButton;
    [saveButton addTarget:self action:@selector(onTapSave:) forControlEvents:UIControlEventTouchUpInside];
    [saveButton setBackgroundImage:[UIImage imageNamed:@"mf_performance_monitor_save"] forState:UIControlStateNormal];
    
}

#pragma mark - UIActions

- (void)onTapRecord:(id)sender
{
    if ([MFPerformanceMonitorManager sharedManager].isEnable) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            static NSString *const kMFPerformanceMonitorDisable = @"kMFPerformanceMonitorDisable";
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            if ([userDefaults integerForKey:kMFPerformanceMonitorDisable] == 0) {
                [userDefaults setInteger:1 forKey:kMFPerformanceMonitorDisable];
                [userDefaults synchronize];
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"暂停性能监控" message:@"确定暂停吗？\n暂停后将停止性能监控，之后你仍可以点击红色录制按钮继续监控" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定暂停", nil];
                [alertView show];
                
                return;
            }
        });
        
        [self disableMonitor];
    } else {
        [self enableMonitor];
    }
}

- (void)disableMonitor
{
    [MFPerformanceMonitorManager sharedManager].isEnable = NO;
    [[MFPerformanceMonitorManager sharedManager].performanceModel cancelSamplingTimer];
    [_recordButton setBackgroundImage:[UIImage imageNamed:@"mf_performance_monitor_record"] forState:UIControlStateNormal];
}

- (void)enableMonitor
{
    [MFPerformanceMonitorManager sharedManager].isEnable = YES;
    [[MFPerformanceMonitorManager sharedManager].performanceModel startSamplingTimer];
    [_recordButton setBackgroundImage:[UIImage imageNamed:@"mf_performance_monitor_stop"] forState:UIControlStateNormal];
}

- (void)onTapChart:(id)sender
{
    MFPerformanceMonitorViewController *performanceMonitorVC = [MFPerformanceMonitorViewController new];
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:performanceMonitorVC];
    [self presentViewController:navi animated:YES completion:nil];
}

- (void)onTapSave:(id)sender
{
    [self saveToLoaclFile];
}

- (void)saveToLoaclFile
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMdd_HH_mm_ss"];
    NSString *stringFromDate = [formatter stringFromDate:[NSDate date]];
    
    [[MFPerformanceMonitorManager sharedManager].performanceModel saveToLocal:stringFromDate];
}

#pragma mark - PointInside

- (BOOL)shouldReceiveTouchAtWindowPoint:(CGPoint)pointInWindowCoordinates
{
    BOOL shouldReceiveTouch = NO;
    
    CGPoint pointInLocalCoordinates = [self.view convertPoint:pointInWindowCoordinates fromView:nil];
    
    if (CGRectContainsPoint(self.performanceView.frame, pointInLocalCoordinates)) {
        shouldReceiveTouch = YES;
    }
    
    if (!shouldReceiveTouch && self.presentedViewController) {
        shouldReceiveTouch = YES;
    }
    
    return shouldReceiveTouch;
}

#pragma mark - delegates

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView.title isEqualToString:@"暂停性能监控"]) {
        if (buttonIndex != alertView.cancelButtonIndex) {
            [self disableMonitor];
        }
    } else {
        if (buttonIndex != alertView.cancelButtonIndex) {
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = alertView.message;
        }
    }
}

#pragma mark - Gesture

- (void)handlePan:(UIPanGestureRecognizer *)gestureRecognizer
{
    UIGestureRecognizerState state = gestureRecognizer.state;
    
    if (state == UIGestureRecognizerStateChanged) {
        UIWindow *performanceMonitorWindow = (UIWindow *)[MFPerformanceMonitorManager sharedManager].performanceMonitorWindow;
        CGPoint translation = [gestureRecognizer translationInView:performanceMonitorWindow];
        _performanceView.center = CGPointMake(_performanceView.center.x + translation.x,
                                           _performanceView.center.y + translation.y);
        [gestureRecognizer setTranslation:CGPointZero inView:performanceMonitorWindow];
    } else if (state == UIGestureRecognizerStateEnded) {
        CGPoint center = _performanceView.center;
        CGFloat newCenterX;
        
        if (center.x <= [UIScreen mainScreen].bounds.size.width / 2) {
            newCenterX = _performanceView.bounds.size.width / 2;
        } else {
            newCenterX = [UIScreen mainScreen].bounds.size.width - _performanceView.bounds.size.width / 2;
        }
        
        CGFloat newCenterY = _performanceView.center.y;
        CGFloat minCenterY = _performanceView.bounds.size.height / 2   + CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
        CGFloat maxCenterY = [UIScreen mainScreen].bounds.size.height  - _performanceView.bounds.size.height / 2;
        
        if (newCenterY < minCenterY) {
            newCenterY = minCenterY;
        } else if (newCenterY > maxCenterY) {
            newCenterY = maxCenterY;
        }
        
        [UIView animateWithDuration:.25 delay:0 usingSpringWithDamping:.5 initialSpringVelocity:15 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            _performanceView.center = CGPointMake(newCenterX, newCenterY);
        } completion:nil];
    }
}

@end

#endif