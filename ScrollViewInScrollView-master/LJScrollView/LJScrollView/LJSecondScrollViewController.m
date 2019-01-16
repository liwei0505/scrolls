//
//  LJSecondScrollViewController.m
//  LJDemo
//
//  Created by lj on 2017/5/5.
//  Copyright © 2017年 LJ. All rights reserved.
//

#import "LJSecondScrollViewController.h"
#import "LJDynamicItem.h"
#import "MJRefresh.h"

#define NavigationBarHeight 64
#define ScrollViewHeight ([UIScreen mainScreen].bounds.size.height - NavigationBarHeight-60)

#define CenterViewHeight 50
#define HeaderViewHeight 50

/*f(x, d, c) = (x * d * c) / (d + c * x)
 where,
 x – distance from the edge
 c – constant (UIScrollView uses 0.55)
 d – dimension, either width or height*/

static CGFloat rubberBandDistance(CGFloat offset, CGFloat dimension) {
    
    const CGFloat constant = 0.55f;
    CGFloat result = (constant * fabs(offset) * dimension) / (dimension + constant * fabs(offset));
    // The algorithm expects a positive offset, so we have to negate the result if the offset was negative.
    return offset < 0.0f ? -result : result;
}

@interface LJSecondScrollViewController ()<UITableViewDelegate,UITableViewDataSource,UIGestureRecognizerDelegate> {
    CGFloat width;
    CGFloat height;
    CGFloat currentScorllY;
    
    NSMutableArray *tableArray;
    
    __block BOOL isVertical;//是否是垂直
    UIPanGestureRecognizer *pan;
}

@property (nonatomic, strong) UIScrollView *mainScrollView;
@property (nonatomic, strong) UIScrollView *webViewScrollView;
@property (nonatomic, strong) UIScrollView *subScrollView;
@property (nonatomic, strong) UITableView *subTableView;


//弹性和惯性动画
@property (nonatomic, strong) UIDynamicAnimator *animator;
@property (nonatomic, weak) UIDynamicItemBehavior *decelerationBehavior;
@property (nonatomic, strong) LJDynamicItem *dynamicItem;
@property (nonatomic, weak) UIAttachmentBehavior *springBehavior;
@end

@implementation LJSecondScrollViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    width = [UIScreen mainScreen].bounds.size.width;
    height = [UIScreen mainScreen].bounds.size.height;
   
    [self.view addSubview:self.mainScrollView];
    
    UIView *viewHeader = [[UIView alloc]initWithFrame:CGRectMake(0, 0, width, HeaderViewHeight)];
    viewHeader.backgroundColor = [UIColor purpleColor];
    [self.mainScrollView addSubview:viewHeader];
    
    self.webViewScrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, HeaderViewHeight, width, ScrollViewHeight)];
    self.webViewScrollView.layer.borderWidth = 1;
    self.webViewScrollView.layer.borderColor = [UIColor redColor].CGColor;
    self.webViewScrollView.contentSize = CGSizeMake(width, ScrollViewHeight+150);
    self.webViewScrollView.scrollEnabled = NO;
    
    UIView *view1 = [[UIView alloc]initWithFrame:CGRectMake(0, 0, width, ScrollViewHeight)];
    view1.backgroundColor = [UIColor grayColor];
    [self.webViewScrollView addSubview:view1];
    
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, width-10, ScrollViewHeight -30)];
    view.backgroundColor = [UIColor redColor];
    [self.webViewScrollView addSubview:view];
    
    [self.mainScrollView addSubview:self.webViewScrollView];
    
    UIView *viewCenter = [[UIView alloc]initWithFrame:CGRectMake(0, HeaderViewHeight+ScrollViewHeight, width, CenterViewHeight)];
    viewCenter.backgroundColor = [UIColor blueColor];
    [self.mainScrollView addSubview:viewCenter];
    
    [self.mainScrollView addSubview:self.subScrollView];
    self.mainScrollView.contentSize = CGSizeMake(width, HeaderViewHeight+ScrollViewHeight + CenterViewHeight + self.subScrollView.frame.size.height);
    
    pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panGestureRecognizerAction:)];
    pan.delegate = self;
    [self.view addGestureRecognizer:pan];
    
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    self.dynamicItem = [[LJDynamicItem alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidDisappear:(BOOL)animated {
    [self.animator removeAllBehaviors];
}

- (UIScrollView *)mainScrollView {
    if (_mainScrollView == nil) {
        _mainScrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, NavigationBarHeight, width, height - NavigationBarHeight)];
        _mainScrollView.delegate = self;
        _mainScrollView.scrollEnabled = NO;
    }
    return _mainScrollView;
}

- (UIScrollView *)subScrollView {
    if (_subScrollView == nil) {
        _subScrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, HeaderViewHeight+ ScrollViewHeight+CenterViewHeight, width, height - 64)];
        _subScrollView.contentSize = CGSizeMake(width * 3, _subScrollView.frame.size.height);
        _subScrollView.pagingEnabled = YES;
        _subScrollView.scrollEnabled = YES;
        _subScrollView.delegate = self;
        _subScrollView.layer.borderWidth = 1;
        _subScrollView.layer.borderColor = [UIColor greenColor].CGColor;
        tableArray = [NSMutableArray array];
        for (int i = 0; i < 3; i++) {
            UITableView *tableView = [[UITableView alloc]initWithFrame:CGRectMake(i * width, 0, width, _subScrollView.frame.size.height)];
            tableView.delegate = self;
            tableView.dataSource = self;
            tableView.scrollEnabled = NO;
            tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
                NSLog(@"mj_footer");
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [tableView.mj_footer  endRefreshing];
                });
            }];
            ((MJRefreshAutoNormalFooter *)tableView.mj_footer).automaticallyRefresh = NO;
            
            [tableView.mj_footer beginRefreshing];
            [_subScrollView addSubview:tableView];
            [tableArray addObject:tableView];
        }
        self.subTableView = tableArray.firstObject;
    }
    return _subScrollView;
}


#pragma mark - UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView  == tableArray[0]) {
        return 5;
    }
    return 26;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCellID"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UITableViewCellID"];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"第%ld行",(long)indexPath.row];
    return cell;
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView == self.subScrollView) {
        CGFloat a = self.subScrollView.contentOffset.x/self.subScrollView.frame.size.width;
        self.subTableView = [tableArray objectAtIndex:a];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        UIPanGestureRecognizer *recognizer = (UIPanGestureRecognizer *)gestureRecognizer;
        CGFloat currentY = [recognizer translationInView:self.view].y;
        CGFloat currentX = [recognizer translationInView:self.view].x;
        
        if (currentY == 0.0) {
            return NO;
        } else {
            if (fabs(currentX)/fabs(currentY) >= 5.0) {
                return YES;
            } else {
                return NO;
            }
        }
    }
    return NO;
}

- (void)panGestureRecognizerAction:(UIPanGestureRecognizer *)recognizer {
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            currentScorllY = self.mainScrollView.contentOffset.y;
            CGFloat currentY = [recognizer translationInView:self.view].y;
            CGFloat currentX = [recognizer translationInView:self.view].x;
            
            if (currentY == 0.0) {
//                isVertical = NO;
                isVertical = YES;
            } else {
                if (fabs(currentX)/fabs(currentY) >= 5.0) {
                    isVertical = NO;
                } else {
                    isVertical = YES;
                }
            }
            [self.animator removeAllBehaviors];
            break;
        case UIGestureRecognizerStateChanged:
        {
            //locationInView:获取到的是手指点击屏幕实时的坐标点；
            //translationInView：获取到的是手指移动后，在相对坐标中的偏移量
            
            if (isVertical) {
                //往上滑为负数，往下滑为正数
                CGFloat currentY = [recognizer translationInView:self.view].y;
                [self controlScrollForVertical:currentY AndState:UIGestureRecognizerStateChanged];
                NSLog(@"Changed-- currentY:%f",currentY);
            }
        }
            break;
        case UIGestureRecognizerStateCancelled:
            
            break;
        case UIGestureRecognizerStateEnded:
        {
            if (isVertical) {
                self.dynamicItem.center = self.view.bounds.origin;
                //velocity是在手势结束的时候获取的竖直方向的手势速度
                CGPoint velocity = [recognizer velocityInView:self.view];
                UIDynamicItemBehavior *inertialBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.dynamicItem]];
                [inertialBehavior addLinearVelocity:CGPointMake(0, velocity.y) forItem:self.dynamicItem];
                // 通过尝试取2.0比较像系统的效果
                inertialBehavior.resistance = 2.0;
                __block CGPoint lastCenter = CGPointZero;
                __weak typeof(self) weakSelf = self;
                inertialBehavior.action = ^{
                    if (isVertical) {
                        //得到每次移动的距离
                        CGFloat currentY = weakSelf.dynamicItem.center.y - lastCenter.y;
                        [weakSelf controlScrollForVertical:currentY AndState:UIGestureRecognizerStateEnded];
                        NSLog(@"end-- currentY:%f %f %f",currentY,weakSelf.dynamicItem.center.y,lastCenter.y);
                    }
                    lastCenter = weakSelf.dynamicItem.center;
                };
                [self.animator addBehavior:inertialBehavior];
                self.decelerationBehavior = inertialBehavior;
            }
        }
            break;
        default:
            break;
    }
    //保证每次只是移动的距离，不是从头一直移动的距离
    [recognizer setTranslation:CGPointZero inView:self.view];
}

-(CGFloat)subTableBeginY{
    return HeaderViewHeight + ScrollViewHeight + CenterViewHeight;
}
-(CGFloat)webViewBeginY{
    return HeaderViewHeight;
}

//控制上下滚动的方法
- (void)controlScrollForVertical:(CGFloat)detal AndState:(UIGestureRecognizerState)state {
    //判断是主ScrollView滚动还是子ScrollView滚动,detal为手指移动的距离
    if (self.mainScrollView.contentOffset.y >= self.subTableBeginY) {
        CGFloat offsetY = self.subTableView.contentOffset.y - detal;
        if (offsetY < 0) {
            //当子ScrollView的contentOffset小于0之后就不再移动子ScrollView，而要移动主ScrollView
            offsetY = 0;
            self.mainScrollView.contentOffset = CGPointMake(self.mainScrollView.frame.origin.x, self.mainScrollView.contentOffset.y - detal);
        } else if (offsetY > (self.subTableView.contentSize.height - self.subTableView.frame.size.height)) {
            //当子ScrollView的contentOffset大于tableView的可移动距离时
            offsetY = self.subTableView.contentOffset.y - rubberBandDistance(detal, height);
        }
        NSLog(@"subTableView -- %f",offsetY);
        self.subTableView.contentOffset = CGPointMake(0, offsetY);
    }
    else if(self.mainScrollView.contentOffset.y <= self.webViewBeginY){
        CGFloat mainOffsetY = self.mainScrollView.contentOffset.y - detal;
        CGFloat offsetY = self.webViewScrollView.contentOffset.y - detal;
        if(mainOffsetY<0 && offsetY<0){
            mainOffsetY = self.mainScrollView.contentOffset.y - rubberBandDistance(detal, height);
            self.mainScrollView.contentOffset = CGPointMake(self.mainScrollView.frame.origin.x, mainOffsetY);
            self.webViewScrollView.contentOffset = CGPointMake(0, 0);
        }else if(mainOffsetY>=0 && mainOffsetY<self.webViewBeginY && ((offsetY<0&&detal>0)||(offsetY>0&&detal<0)||(detal==0 && offsetY==0))){
            self.mainScrollView.contentOffset = CGPointMake(self.mainScrollView.frame.origin.x, self.mainScrollView.contentOffset.y - detal);
        }else{
            
            if (offsetY < 0) {
//              //当子ScrollView的contentOffset小于0
//                 offsetY = self.webViewScrollView.contentOffset.y - rubberBandDistance(detal, height);
            } else if (offsetY > (self.webViewScrollView.contentSize.height - self.webViewScrollView.frame.size.height)) {
                //当子ScrollView的contentOffset大于tableView的可移动距离时之后就不再移动子ScrollView，而要移动主ScrollView
                
                offsetY = self.webViewScrollView.contentSize.height - self.webViewScrollView.frame.size.height;
                self.mainScrollView.contentOffset = CGPointMake(self.mainScrollView.frame.origin.x, self.mainScrollView.contentOffset.y - detal);
            }
            NSLog(@"webViewScrollView -- %f",offsetY);
            self.webViewScrollView.contentOffset = CGPointMake(0, offsetY);
        }
    }
    else {
        CGFloat mainOffsetY = self.mainScrollView.contentOffset.y - detal;
        if (mainOffsetY < 0) {
            //滚到顶部之后继续往上滚动需要乘以一个小于1的系数
            mainOffsetY = 0;
//            mainOffsetY = self.mainScrollView.contentOffset.y - rubberBandDistance(detal, height);//刹车 - 回弹效果

        } else if (mainOffsetY > self.subTableBeginY) {
            mainOffsetY = self.subTableBeginY;
        }
        
        NSLog(@"mainScrollView -- %f",mainOffsetY);
        self.mainScrollView.contentOffset = CGPointMake(self.mainScrollView.frame.origin.x, mainOffsetY);

        if (mainOffsetY == 0) {
            for (UITableView *tableView in tableArray) {
                tableView.contentOffset = CGPointMake(0, 0);
            }
        }
    }
    
    BOOL outsideFrame = [self outsideFrame];
    if (outsideFrame &&
        (self.decelerationBehavior && !self.springBehavior)) {
        CGPoint target = CGPointZero;
        id targetView = nil;
         if(self.webViewScrollView.contentOffset.y < 0){
            self.dynamicItem.center = self.webViewScrollView.contentOffset;
            target = CGPointZero;
            targetView = self.webViewScrollView;
        } else if (self.mainScrollView.contentOffset.y >= self.subTableBeginY && self.subTableView.contentOffset.y > (self.subTableView.contentSize.height - self.subTableView.frame.size.height)) {
            self.dynamicItem.center = self.subTableView.contentOffset;
            
            target.x = self.subTableView.contentOffset.x;
            target.y = self.subTableView.contentSize.height > self.subTableView.frame.size.height ? self.subTableView.contentSize.height - self.subTableView.frame.size.height: 0;
            targetView = self.subTableView;
        } else if (self.mainScrollView.contentOffset.y < 0) {
            self.dynamicItem.center = self.mainScrollView.contentOffset;
            target = CGPointZero;
            targetView = self.mainScrollView;
        }
        [self.animator removeBehavior:self.decelerationBehavior];
        __weak typeof(self) weakSelf = self;
        UIAttachmentBehavior *springBehavior = [[UIAttachmentBehavior alloc] initWithItem:self.dynamicItem attachedToAnchor:target];
        springBehavior.length = 0;
        springBehavior.damping = 1;
        springBehavior.frequency = 2;
        springBehavior.action = ^{
            if ([targetView isEqual:weakSelf.webViewScrollView]) {
                weakSelf.webViewScrollView.contentOffset = weakSelf.dynamicItem.center;
            } else if ([targetView isEqual:weakSelf.subTableView]) {
                weakSelf.subTableView.contentOffset = weakSelf.dynamicItem.center;
                if (weakSelf.subTableView.mj_footer.refreshing) {
                    weakSelf.subTableView.contentOffset = CGPointMake(weakSelf.subTableView.contentOffset.x, weakSelf.subTableView.contentOffset.y + 44);
                }
            }else if ([targetView isEqual:weakSelf.mainScrollView]) {
                weakSelf.mainScrollView.contentOffset = weakSelf.dynamicItem.center;
                if (weakSelf.mainScrollView.contentOffset.y == 0) {
                    for (UITableView *tableView in tableArray) {
                        tableView.contentOffset = CGPointMake(0, 0);
                    }
                }
            }
        };
        [self.animator addBehavior:springBehavior];
        self.springBehavior = springBehavior;
    }
}

//判断是否超出ViewFrame边界
- (BOOL)outsideFrame {
    
    if (self.subTableView.contentSize.height > self.subTableView.frame.size.height) {
        if (self.subTableView.contentOffset.y > (self.subTableView.contentSize.height - self.subTableView.frame.size.height)) {
            //最下面
            return YES;
        }
    }else if (self.subTableView.contentOffset.y > 0){
        return YES;
    }
    
    if (self.webViewScrollView.contentSize.height > self.webViewScrollView.frame.size.height) {
        if (self.webViewScrollView.contentOffset.y < 0) {
            //最上面
            return YES;
        }
    }else if (self.webViewScrollView.contentOffset.y > 0){
        return YES;
    }
    
    if (self.mainScrollView.contentOffset.y < 0) {
        return YES;
    }
    
    return NO;
}



@end
