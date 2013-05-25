//
//  StrollViewController.m
//  XWQSBK
//
//  Created by Ren XinWei on 13-5-3.
//  Copyright (c) 2013年 renxinwei. All rights reserved.
//

#import "StrollViewController.h"

@interface StrollViewController ()

@end

@implementation StrollViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    _isLoaded = YES;
    _suggestLoaded = NO;
    _latestLoaded = NO;
    [self initSliderSwitch];
    [self initViews];
    
    if (_refreshHeaderView == nil) {
        EGORefreshTableHeaderView *view = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0, 0 - CGRectGetHeight(_strollTableView.bounds), CGRectGetWidth(self.view.frame), CGRectGetHeight(_strollTableView.bounds))];
        view.delegate = self;
        [_strollTableView addSubview:view];
        _refreshHeaderView = view;
        [view release];
    }
    
    if (_loadMoreFooterView ==nil) {
        _loadMoreFooterView = [[LoadMoreFooterView alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
        _loadMoreFooterView.delegate = self;
        _strollTableView.tableFooterView = _loadMoreFooterView;
        _strollTableView.tableFooterView.hidden = NO;
    }
    
    [_refreshHeaderView refreshLastUpdatedDate];
    
    _requestType = RequestTypeNormal;
    _qiushiType = QiuShiTypeSuggest;
    _currentSuggestPage = 1;
    _currentLatestPage = 1;
    _strollSuggestArray = [[NSMutableArray alloc] initWithCapacity:0];
    _strollLatestArray = [[NSMutableArray alloc] initWithCapacity:0];
    [self initStrollRequestWithType:_qiushiType andPage:_currentSuggestPage];
    _suggestLoaded = YES;
    [self refreshed];
}

- (void)dealloc
{
    ClearRequest(_strollRequest);
    [_refreshHeaderView release];
    [_loadMoreFooterView release];
    [_strollSuggestArray release];
    [_strollLatestArray release];
    [_sliderSwitch release];
    [_strollTableView release];
    [_sideButton release];
    [_postButton release];
    [super dealloc];
}

- (void)viewDidUnload
{
    [self setStrollTableView:nil];
    [self setSideButton:nil];
    [self setPostButton:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    NSLog(@"rotate");
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - UITableView datasource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _qiushiType == QiuShiTypeSuggest ? [_strollSuggestArray count] : [_strollLatestArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"StrollCellIdentifier";
    UITableViewCell *cell = (QiuShiCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"QiuShiCell" owner:self options:nil] lastObject];
        UIImage *backgroundImage = [UIImage imageNamed:@"block_background.png"];
        backgroundImage = [backgroundImage resizableImageWithCapInsets:UIEdgeInsetsMake(15, 320, 14, 0)];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:backgroundImage];
        [cell setBackgroundView:imageView];
        [imageView release];
        ((QiuShiCell *)cell).delegate = self;
    }

    NSMutableArray *strollArray = _qiushiType == QiuShiTypeSuggest ? _strollSuggestArray : _strollLatestArray;
    [((QiuShiCell *)cell) configQiuShiCellWithQiuShi:[strollArray objectAtIndex:indexPath.row]];

    return cell;
}

#pragma mark - UITableView delegate method

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *strollArray = _qiushiType == QiuShiTypeSuggest ? _strollSuggestArray : _strollLatestArray;
    
    return [QiuShiCell getCellHeight:[strollArray objectAtIndex:indexPath.row]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    QiuShiDetailViewController *detailVC = [[[QiuShiDetailViewController alloc] initWithNibName:@"QiuShiDetailViewController" bundle:nil] autorelease];
    NSMutableArray *strollArray = _qiushiType == QiuShiTypeSuggest ? _strollSuggestArray : _strollLatestArray;
    QiuShi *qs = (QiuShi *)[strollArray objectAtIndex:indexPath.row];
    detailVC.qiushi = qs;
    detailVC.title = [NSString stringWithFormat:@"糗事%@", qs.qiushiID];
    [self.navigationController pushViewController:detailVC animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UIScrollView delegate method

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (_qiushiType == QiuShiTypeSuggest) {
        _strollSuggestPoint = scrollView.contentOffset;
    }
    else {
        _strollLatestPoint = scrollView.contentOffset;
    }
    
    [_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
    [_loadMoreFooterView loadMoreScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
    [_loadMoreFooterView loadMoreshScrollViewDidEndDragging:scrollView];
}

#pragma mark - EGORefreshTableHeaderDelegate methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView *)view
{
    _reloading = YES;
    _requestType = RequestTypeNormal;
    
    if (_qiushiType == QiuShiTypeSuggest) {
        _currentSuggestPage = 1;
        [self initStrollRequestWithType:_qiushiType andPage:_currentSuggestPage];
    }
    else {
        _currentLatestPage = 1;
        [self initStrollRequestWithType:_qiushiType andPage:_currentLatestPage];
    }
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView *)view
{
    return _reloading;
}

- (NSDate *)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView *)view
{
    return [NSDate date];
}

#pragma mark - LoadMoreFooterView delegate method

- (void)loadMoreTableFooterDidTriggerRefresh:(LoadMoreFooterView *)view
{
    _reloading = YES;
    _requestType = RequestTypeLoadMore;
    
    if (_qiushiType == QiuShiTypeSuggest) {
        _currentSuggestPage++;
        [self initStrollRequestWithType:_qiushiType andPage:_currentSuggestPage];
    }
    else {
        _currentLatestPage++;
        [self initStrollRequestWithType:_qiushiType andPage:_currentLatestPage];
    }
}

#pragma mark - ASIHttpRequest delegate methods

- (void)requestFinished:(ASIHTTPRequest *)request
{
    JSONDecoder *jsonDecoder = [[JSONDecoder alloc] init];
    NSDictionary *dic = [jsonDecoder objectWithData:[request responseData]];
    [jsonDecoder release];
    
    if (_reloading) {
        _reloading = NO;
        [_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:_strollTableView];
        [_loadMoreFooterView loadMoreshScrollViewDataSourceDidFinishedLoading:_strollTableView];
    }
    
    if (_requestType == RequestTypeNormal) {
        NSMutableArray *strollArray = _qiushiType == QiuShiTypeSuggest ? _strollSuggestArray : _strollLatestArray;
        [strollArray removeAllObjects];
    }
    
    NSArray *array = [dic objectForKey:@"items"];
    if (array) {
        for (int i = 0; i < [array count]; i++) {
            NSDictionary *qiushiDic = [array objectAtIndex:i];
            QiuShi *qs = [[QiuShi alloc] initWithQiuShiDictionary:qiushiDic];
            NSMutableArray *strollArray = _qiushiType == QiuShiTypeSuggest ? _strollSuggestArray : _strollLatestArray;
            [strollArray addObject:qs];
            [qs release];
        }
    }
    
    [_strollTableView reloadData];
}

- (void)refreshed
{
    [_strollTableView setContentOffset:CGPointMake(0, -75) animated:YES];
    [self performSelector:@selector(doneManualRefresh) withObject:nil afterDelay:1];
}

- (void)doneManualRefresh
{
    [_refreshHeaderView egoRefreshScrollViewDidScroll:_strollTableView];
    [_refreshHeaderView egoRefreshScrollViewDidEndDragging:_strollTableView];
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    NSLog(@"服务不可用");
}

#pragma mark - XWSliderSwitchDelegate method 

- (void)slideView:(XWSliderSwitch *)slideSwitch switchChangedAtIndex:(NSInteger)index
{
    //_qiushiType = index == 0 ? QiuShiTypeSuggest : QiuShiTypeLatest;
    if (index == 0) {
        _qiushiType = QiuShiTypeSuggest;
        if (!_suggestLoaded) {
            //[self refreshed];
            [self initStrollRequestWithType:_qiushiType andPage:1];
            _suggestLoaded = YES;
        }
        else {
            [_strollTableView reloadData];
            [_strollTableView setContentOffset:_strollSuggestPoint];
        }
    }
    else {
        _qiushiType = QiuShiTypeLatest;
        if (!_latestLoaded) {
            //[self refreshed];
            [self initStrollRequestWithType:_qiushiType andPage:1];
            _latestLoaded = YES;
        }
        else {
            [_strollTableView reloadData];
            [_strollTableView setContentOffset:_strollLatestPoint];
        }
    }
}

#pragma mark - QiuShiCellDelegate method

- (void)didTapedQiuShiCellImage:(NSString *)midImageURL
{
    QiuShiImageViewController *qiushiImageVC = [[QiuShiImageViewController alloc] initWithNibName:@"QiuShiImageViewController" bundle:nil];
    [qiushiImageVC setQiuShiImageURL:midImageURL];
    qiushiImageVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    [self presentViewController:qiushiImageVC animated:YES completion:nil];
    [qiushiImageVC release];
}

#pragma mark - UIAction methods

- (IBAction)sideButtonClicked:(id)sender
{
    SideBarShowDirection direction = [SideBarViewController getShowingState] ? SideBarShowDirectionNone : SideBarShowDirectionLeft;
    if ([[SideBarViewController share] respondsToSelector:@selector(showSideBarControllerWithDirection:)]) {
        [[SideBarViewController share] showSideBarControllerWithDirection:direction];
    }
}

- (IBAction)postButtonClicked:(id)sender
{
    
}

#pragma mark - Private methods

- (void)initViews
{
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"main_background.png"]]];
    
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:_sideButton] autorelease];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:_postButton] autorelease];
    self.navigationItem.titleView = _sliderSwitch;
    self.strollTableView.scrollsToTop = YES;
}

- (void)initSliderSwitch
{
    _sliderSwitch = [[XWSliderSwitch alloc] initWithFrame:CGRectMake(0, 0, 118, 29)];
    _sliderSwitch.labelCount = 2;
    _sliderSwitch.delegate = self;
    [_sliderSwitch initSliderSwitch];
    [_sliderSwitch setSliderSwitchBackground:[UIImage imageNamed:@"top_tab_background2.png"]];
    [_sliderSwitch setLabelOneText:@"干货"];
    [_sliderSwitch setLabelTwoText:@"嫩草"];
}

- (void)initStrollRequestWithType:(QiuShiType)type andPage:(NSInteger)page
{
    NSURL *url = nil;
    if (type == QiuShiTypeSuggest) {
        url = [NSURL URLWithString:api_stroll_suggest(30, page)];
    }
    else {
        url = [NSURL URLWithString:api_stroll_latest(30, page)];
    }
    _strollRequest = [ASIHTTPRequest requestWithURL:url];
    _strollRequest.delegate = self;
    [_strollRequest startAsynchronous];
}

@end