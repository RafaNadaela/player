/*!
 @header TencentNewsViewController.m
 
 @abstract  作者Github地址：https://github.com/zhengwenming
            作者CSDN博客地址:http://blog.csdn.net/wenmingzheng
 
 @author   Created by zhengwenming on  16/1/19
 
 @version 1.00 16/1/19 Creation(版本信息)
 
   Copyright © 2016年 郑文明. All rights reserved.
 */

#import "TencentNewsViewController.h"
#import "SidModel.h"
#import "VideoCell.h"
#import "VideoModel.h"
#import "WMPlayer.h"
#import "DetailViewController.h"


@interface TencentNewsViewController ()<UITableViewDelegate,UITableViewDataSource,UIScrollViewDelegate>{
    NSMutableArray *dataSource;
    WMPlayer *wmPlayer;
    NSIndexPath *currentIndexPath;
    BOOL isSmallScreen;
}
@property(nonatomic,retain)VideoCell *currentCell;

@end

@implementation TencentNewsViewController
- (instancetype)init{
    self = [super init];
    if (self) {
        dataSource = [NSMutableArray array];
        isSmallScreen = NO;
    }
    return self;
}

// 这一个 方法是系统 自带的 ,是否 要隐藏 状态栏

-(BOOL)prefersStatusBarHidden{
    if (wmPlayer) {
        if (wmPlayer.isFullscreen) {
            return YES;
        }else{
            return NO;
        }
    }else{
        return NO;
    }
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];

    //旋转屏幕通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeviceOrientationChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil
     ];
}
-(void)videoDidFinished:(NSNotification *)notice{
    VideoCell *currentCell = (VideoCell *)[self.table cellForRowAtIndexPath:[NSIndexPath indexPathForRow:currentIndexPath.row inSection:0]];
    [currentCell.playBtn.superview bringSubviewToFront:currentCell.playBtn];
    //播放完 要把这个播放器 释放掉
    
    [self releaseWMPlayer];
    [self setNeedsStatusBarAppearanceUpdate];
}
-(void)closeTheVideo:(NSNotification *)obj{
    VideoCell *currentCell = (VideoCell *)[self.table cellForRowAtIndexPath:[NSIndexPath indexPathForRow:currentIndexPath.row inSection:0]];
    
    //这句话的含义就是 ,playbtn 所在的 view 播放完 ,再让这个but 显示到最上面
    
    [currentCell.playBtn.superview bringSubviewToFront:currentCell.playBtn];
    
    //[currentCell.playBtn.superview sendSubviewToBack:currentCell.playBtn];
    
    [self releaseWMPlayer];
    [self setNeedsStatusBarAppearanceUpdate];
}


-(void)fullScreenBtnClick:(NSNotification *)notice{
    
    UIButton *fullScreenBtn = (UIButton *)[notice object];
    
    if (fullScreenBtn.isSelected) {//全屏显示
        [self toFullScreenWithInterfaceOrientation:UIInterfaceOrientationLandscapeLeft];
    }else{
        if (isSmallScreen) {
            //放widow上,小屏显示
            [self toSmallScreen];
        }
        else{
            
//这一个 就是既不是全屏 也不是小屏幕播放 , 那么就把他放到 cell上 播放
            [self toCell];
        }
    }
}
/**
 *  旋转屏幕通知
 */
- (void)onDeviceOrientationChange{
    if (wmPlayer==nil||wmPlayer.superview==nil){
        return;
    }
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    UIInterfaceOrientation interfaceOrientation = (UIInterfaceOrientation)orientation;
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortraitUpsideDown:{
            NSLog(@"第3个旋转方向---电池栏在下");
        }
            break;
        case UIInterfaceOrientationPortrait:{
            NSLog(@"第0个旋转方向---电池栏在上");
            if (wmPlayer.isFullscreen) {
                if (isSmallScreen) {
                    //放widow上,小屏显示
                    [self toSmallScreen];
                }else{
                    [self toCell];
                }
            }
        }
            break;
        case UIInterfaceOrientationLandscapeLeft:{
            NSLog(@"第2个旋转方向---电池栏在左");
            if (wmPlayer.isFullscreen == NO) {
                wmPlayer.isFullscreen = YES;

                [self setNeedsStatusBarAppearanceUpdate];
                [self toFullScreenWithInterfaceOrientation:interfaceOrientation];
            }
        }
            break;
        case UIInterfaceOrientationLandscapeRight:{
            NSLog(@"第1个旋转方向---电池栏在右");
            if (wmPlayer.isFullscreen == NO) {
                wmPlayer.isFullscreen = YES;
                [self setNeedsStatusBarAppearanceUpdate];
                [self toFullScreenWithInterfaceOrientation:interfaceOrientation];
            }
        }
            break;
        default:
            break;
    }
}

#warning  这一个是设置 在 cell 上的  wmPlayer 的尺寸

-(void)toCell{
    VideoCell *currentCell = [self currentCell];
    
    [wmPlayer removeFromSuperview];
    NSLog(@"row = %ld",currentIndexPath.row);
    [UIView animateWithDuration:0.5f animations:^{
        //放缩比例
        wmPlayer.transform = CGAffineTransformIdentity;
        
        wmPlayer.frame = currentCell.backgroundIV.bounds;
        
        wmPlayer.playerLayer.frame =  wmPlayer.bounds;
        
        [currentCell.backgroundIV addSubview:wmPlayer];
        
        [currentCell.backgroundIV bringSubviewToFront:wmPlayer];
        
 // 在 cell上设置 bottomview
        
        [wmPlayer.bottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(wmPlayer).with.offset(0);
            make.right.equalTo(wmPlayer).with.offset(0);
            make.height.mas_equalTo(40);
            make.bottom.equalTo(wmPlayer).with.offset(0);
        }];
        
        [wmPlayer.closeBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(wmPlayer).with.offset(5);
            make.height.mas_equalTo(30);
            make.width.mas_equalTo(30);
            make.top.equalTo(wmPlayer).with.offset(5);
        }];
    }completion:^(BOOL finished) {
        
        wmPlayer.isFullscreen = NO;
        
        [self setNeedsStatusBarAppearanceUpdate];
        
        isSmallScreen = NO;
        
        wmPlayer.fullScreenBtn.selected = NO;
        
    }];
    
}
#warning    这一个 是全屏的 情况 去 设置  wmPlayer 的尺寸

-(void)toFullScreenWithInterfaceOrientation:(UIInterfaceOrientation )interfaceOrientation{
    [wmPlayer removeFromSuperview];
    wmPlayer.transform = CGAffineTransformIdentity;
    if (interfaceOrientation==UIInterfaceOrientationLandscapeLeft) {
        wmPlayer.transform = CGAffineTransformMakeRotation(-M_PI_2);
    }else if(interfaceOrientation==UIInterfaceOrientationLandscapeRight){
        wmPlayer.transform = CGAffineTransformMakeRotation(M_PI_2);
    }
    
    wmPlayer.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
    wmPlayer.playerLayer.frame =  CGRectMake(0,0, self.view.frame.size.height,self.view.frame.size.width);
    
    [wmPlayer.bottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(40);
        make.top.mas_equalTo(self.view.frame.size.width-40);
        make.width.mas_equalTo(self.view.frame.size.height);
    }];
    
    [wmPlayer.closeBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(wmPlayer).with.offset((-self.view.frame.size.height/2));
        make.height.mas_equalTo(30);
        make.width.mas_equalTo(30);
        make.top.equalTo(wmPlayer).with.offset(5);
        
    }];
    
    
    [[UIApplication sharedApplication].keyWindow addSubview:wmPlayer];
    

    wmPlayer.fullScreenBtn.selected = YES;
    
    [wmPlayer bringSubviewToFront:wmPlayer.bottomView];
    
   // [wmPlayer bringSubviewToFront:wmPlayer.closeBtn];
    
}

// 这是那 一个 小窗口

-(void)toSmallScreen{
    
#warning   WMPlayer  这一个 自定义的 播放器 是 继承自 UIView的 对于这一个 小的视图 直接添加到整个 window上即可(让他在最前面,优先级最高)
    
    
    
    //放widow上
    [wmPlayer removeFromSuperview];
    
    [UIView animateWithDuration:0.5f animations:^{
        
        
        
        wmPlayer.transform = CGAffineTransformIdentity;
        
        wmPlayer.frame = CGRectMake(kScreenWidth/2,kScreenHeight-kTabBarHeight-(kScreenWidth/2)*0.75, kScreenWidth/2, (kScreenWidth/2)*0.75);
        
        wmPlayer.playerLayer.frame =  wmPlayer.bounds;
        
 //把这个 播放器添加到 window上
        [[UIApplication sharedApplication].keyWindow addSubview:wmPlayer];
        
        [wmPlayer.bottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
            
            make.left.equalTo(wmPlayer).with.offset(0);
            make.right.equalTo(wmPlayer).with.offset(0);
            make.height.mas_equalTo(40);
            make.bottom.equalTo(wmPlayer).with.offset(0);
        }];
        
        [wmPlayer.closeBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
           // make.left.equalTo(wmPlayer).with.offset(5);
            
            make.left.mas_equalTo(wmPlayer.mas_left).mas_offset(5);
            
            make.height.mas_equalTo(30);
            make.width.mas_equalTo(30);
            make.top.equalTo(wmPlayer).with.offset(5);
            
        }];
        
    }completion:^(BOOL finished) {
        wmPlayer.isFullscreen = NO;
        [self setNeedsStatusBarAppearanceUpdate];
        wmPlayer.fullScreenBtn.selected = NO;
        isSmallScreen = YES;
        
//把小视图 放到window的 最上面
        
#warning bringSubviewToFront  把 他的(wmPlayer) 子视图 放到最前面
        
        [[UIApplication sharedApplication].keyWindow bringSubviewToFront:wmPlayer];
    }];
    
}
//要想 有滚动 ,必须结合 scrollView 的 delegate 才可以


#pragma mark scrollView delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if(scrollView ==self.table){
        if (wmPlayer==nil) {
            return;
        }
        
        if (wmPlayer.superview) {
            
            CGRect rectInTableView = [self.table rectForRowAtIndexPath:currentIndexPath];
            
            NSLog(@"-----------222222222-----  %f"    , rectInTableView.origin.y);
            
            // 将rect由rect所在视图转换到目标视图view中，返回在目标视图view中的rect
            
            CGRect rectInSuperview = [self.table convertRect:rectInTableView toView:[self.table superview]];
            
            NSLog(@"1211111      %f" , rectInSuperview.origin.y) ;
            
            if (rectInSuperview.origin.y<-self.currentCell.backgroundIV.frame.size.height||rectInSuperview.origin.y>self.view.frame.size.height-kNavbarHeight-kTabBarHeight)
            {      //往上拖动
                if ([[UIApplication sharedApplication].keyWindow.subviews containsObject:wmPlayer]&&isSmallScreen) {
                    isSmallScreen = YES;
                    
                    [self toSmallScreen];
                    
                    
                }else{
               
                    //放widow上,小屏显示
                    [self toSmallScreen];
                }
                
            }
            else{
                
                [self toCell];
            
            }
        }
        
    }
}




- (void)viewDidLoad {
    [super viewDidLoad];
    //注册播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoDidFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    //注册播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fullScreenBtnClick:) name:WMPlayerFullScreenButtonClickedNotification object:nil];
    
    
    [self.table registerNib:[UINib nibWithNibName:@"VideoCell" bundle:nil] forCellReuseIdentifier: @"VideoCell"];
    
    //关闭视频的 通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeTheVideo:) name : WMPlayerClosedNotification object:nil
     
     ];

    [self addMJRefresh];
}
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self performSelector:@selector(loadData) withObject:nil afterDelay:1.0];

}
-(void)loadData{
    [dataSource addObjectsFromArray:[AppDelegate shareAppDelegate].videoArray];
    [self.table reloadData];

}
-(void)addMJRefresh{
    WS(weakSelf)

 __unsafe_unretained UITableView *tableView = self.table;
 // 下拉刷新
    tableView.mj_header= [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [weakSelf addHudWithMessage:@"加载中..."];
        
        
     [[DataManager shareManager] getSIDArrayWithURLString:@"http://c.m.163.com/nc/video/home/0-10.html"
          success:^(NSArray *sidArray, NSArray *videoArray) {
              
              dataSource =[NSMutableArray arrayWithArray:videoArray];
              
              dispatch_async(dispatch_get_main_queue(), ^{
                  
                  if (currentIndexPath.row>dataSource.count) {
                      
                      [weakSelf releaseWMPlayer];
                      
                  }
                  [weakSelf removeHud];
                  [tableView reloadData];
                  [tableView.mj_header endRefreshing];
              });
          }
           failed:^(NSError *error) {
               [weakSelf removeHud];

           }];
     
    }];
 

 // 设置自动切换透明度(在导航栏下面自动隐藏)
 tableView.mj_header.automaticallyChangeAlpha = YES;
    
    
 // 上拉刷新
 tableView.mj_footer = [MJRefreshBackNormalFooter footerWithRefreshingBlock:^{
     
     NSString *URLString = [NSString stringWithFormat:@"http://c.m.163.com/nc/video/home/%ld-10.html",dataSource.count - dataSource.count%10];
     
     [weakSelf addHudWithMessage:@"加载中..."];
     
     [[DataManager shareManager] getSIDArrayWithURLString:URLString
      success:^(NSArray *sidArray, NSArray *videoArray) {
          [dataSource addObjectsFromArray:videoArray];
          dispatch_async(dispatch_get_main_queue(), ^{
              [weakSelf removeHud];
              [tableView reloadData];
              [tableView.mj_header endRefreshing];
          });

      }
       failed:^(NSError *error) {
           [weakSelf removeHud];
 
       }];
     // 结束刷新
     [tableView.mj_footer endRefreshing];
 }];
 
 
}
                     
-(NSInteger )tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return dataSource.count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 274;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"VideoCell";
    VideoCell *cell = (VideoCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
    
#warning 把这个 模型层传过去就可以了..在自定义的cell中 重写setter方法即可
    
    cell.model = [dataSource objectAtIndex:indexPath.row];
    
    
    //给 cell 上的 button 按钮 添加 响应  事件
    
    [cell.playBtn addTarget:self action:@selector(startPlayVideo:) forControlEvents:UIControlEventTouchUpInside];
    
    cell.playBtn.tag = indexPath.row;
    
    
    if (wmPlayer&&wmPlayer.superview) {
        if (indexPath.row==currentIndexPath.row) {
            [cell.playBtn.superview sendSubviewToBack:cell.playBtn];
        }else{
            [cell.playBtn.superview bringSubviewToFront:cell.playBtn];
        }
        NSArray *indexpaths = [tableView indexPathsForVisibleRows];
        if (![indexpaths containsObject:currentIndexPath]) {//复用
            
            if ([[UIApplication sharedApplication].keyWindow.subviews containsObject:wmPlayer]) {
                wmPlayer.hidden = NO;
                
            }else{
                wmPlayer.hidden = YES;
                [cell.playBtn.superview bringSubviewToFront:cell.playBtn];
            }
        }else{
            if ([cell.backgroundIV.subviews containsObject:wmPlayer]) {
                [cell.backgroundIV addSubview:wmPlayer];
                
                isSmallScreen= NO ;
                
                [wmPlayer play];
                
                wmPlayer.playOrPauseBtn.selected = NO;
                wmPlayer.hidden = NO;
            }
            
        }
    }


    return cell;
}


//点击 开始播放
-(void)startPlayVideo:(UIButton *)sender{
    
    currentIndexPath = [NSIndexPath indexPathForRow:sender.tag inSection:0];
    
    NSLog(@"currentIndexPath.row = %ld",currentIndexPath.row);
    
    if ([UIDevice currentDevice].systemVersion.floatValue>=8||[UIDevice currentDevice].systemVersion.floatValue<7)
    {
        //因为 button 下面(superView)是一个 UITableViewCellContentView , imageView下面才是 cell
        
        self.currentCell = (VideoCell *)sender.superview.superview;
        
        NSLog(@"-00-000-000-0 %@" , sender.superview) ;   //  UITableViewCellContentView
        
        NSLog(@"-------1111111111111----  %@" , sender.superview.superview) ;    //  VideoCell   就是 自定义的 那一个 cell
        
    }else{
        
        //ios7系统 UITableViewCell上多了一个层级UITableViewCellScrollView
        
        self.currentCell = (VideoCell *)sender.superview.superview.subviews;
        
       // NSLog(@"---------22222222222--------   %@"    ,sender.superview.superview) ;
        

    }
    VideoModel *model = [dataSource objectAtIndex:sender.tag];
    
    isSmallScreen = NO;

   
    if (wmPlayer) {
        [wmPlayer removeFromSuperview];
        [wmPlayer.player replaceCurrentItemWithPlayerItem:nil];
        [wmPlayer setVideoURLStr:model.mp4_url];
        [wmPlayer play];

    }else{
        wmPlayer = [[WMPlayer alloc]initWithFrame:self.currentCell.backgroundIV.bounds videoURLStr:model.mp4_url];
        [wmPlayer play];

    }
    
    //把这一个播放器添加到 图片上 ,然后播放的时候 把他添加到 最上面  然后把 那一个button 放到后面去
    [self.currentCell.backgroundIV addSubview:wmPlayer];
    
    [self.currentCell.backgroundIV bringSubviewToFront:wmPlayer];
    
    //让这一个 button 不让他显示
    
    [self.currentCell.playBtn.superview sendSubviewToBack:self.currentCell.playBtn];
    
    [self.table reloadData];

}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    VideoModel *   model = [dataSource objectAtIndex:indexPath.row];

    DetailViewController *detailVC = [[DetailViewController alloc]init];
    detailVC.URLString  = model.m3u8_url;
    detailVC.title = model.title;
//    detailVC.URLString = model.mp4_url;
    [self.navigationController pushViewController:detailVC animated:YES];
    
}
/**
 *  释放WMPlayer
 */
-(void)releaseWMPlayer{
    
    [wmPlayer.player.currentItem cancelPendingSeeks];
    [wmPlayer.player.currentItem.asset cancelLoading];
    [wmPlayer pause];
    
    //移除观察者
    [wmPlayer.currentItem removeObserver:wmPlayer forKeyPath:@"status"];
    
    [wmPlayer removeFromSuperview];
    [wmPlayer.playerLayer removeFromSuperlayer];
    [wmPlayer.player replaceCurrentItemWithPlayerItem:nil];
    wmPlayer.player = nil;
    wmPlayer.currentItem = nil;
    //释放定时器，否侧不会调用WMPlayer中的dealloc方法
    [wmPlayer.autoDismissTimer invalidate];
    wmPlayer.autoDismissTimer = nil;
    [wmPlayer.durationTimer invalidate];
    wmPlayer.durationTimer = nil;
    
    
    wmPlayer.playOrPauseBtn = nil;
    wmPlayer.playerLayer = nil;
    wmPlayer = nil;
    
    currentIndexPath = nil;
}


-(void)dealloc{
    
    NSLog(@"%@ dealloc",[self class]);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [self releaseWMPlayer];
}














@end
