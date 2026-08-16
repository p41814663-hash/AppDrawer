#import <SpringBoard/SpringBoard.h>
#import <SpringBoardFoundation/SpringBoardFoundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

%config(nonfragile-ivars);

static UIViewController *appDrawerVC = nil;
static BOOL isAppDrawerVisible = NO;

@interface AppDrawerViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UISearchBarDelegate>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) NSArray *allApps;
@property (nonatomic, strong) NSArray *filteredApps;
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, assign) BOOL isSearching;
@end

@implementation AppDrawerViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        _allApps = @[];
        _filteredApps = @[];
        _isSearching = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self loadApplications];
}

- (void)setupUI {
    self.view.backgroundColor = [UIColor clearColor];
    
    self.backgroundView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.backgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
    self.backgroundView.alpha = 0;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissDrawer)];
    [self.backgroundView addGestureRecognizer:tap];
    [self.view addSubview:self.backgroundView];
    
    CGFloat drawerHeight = self.view.bounds.size.height * 0.85;
    CGFloat drawerY = self.view.bounds.size.height;
    
    UIView *drawerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, drawerY, self.view.bounds.size.width, drawerHeight)];
    drawerContainer.backgroundColor = [UIColor systemBackgroundColor];
    drawerContainer.layer.cornerRadius = 24;
    drawerContainer.layer.maskedCorners = CACornerMaskLayerMinXMinYCorner | CACornerMaskLayerMaxXMinYCorner;
    drawerContainer.layer.shadowColor = [UIColor blackColor].CGColor;
    drawerContainer.layer.shadowOpacity = 0.3;
    drawerContainer.layer.shadowRadius = 20;
    drawerContainer.layer.shadowOffset = CGSizeMake(0, -5);
    [self.view addSubview:drawerContainer];
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(16, 16, drawerContainer.bounds.size.width - 32, 44)];
    self.searchBar.delegate = self;
    self.searchBar.placeholder = @"Search apps...";
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.backgroundColor = [UIColor secondarySystemBackgroundColor];
    self.searchBar.layer.cornerRadius = 12;
    self.searchBar.clipsToBounds = YES;
    [drawerContainer addSubview:self.searchBar];
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(60, 80);
    layout.minimumInteritemSpacing = 16;
    layout.minimumLineSpacing = 20;
    layout.sectionInset = UIEdgeInsetsMake(16, 20, 20, 20);
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 70, drawerContainer.bounds.size.width, drawerContainer.bounds.size.height - 70) collectionViewLayout:layout];
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.showsVerticalScrollIndicator = NO;
    [self.collectionView registerClass:[AppIconCell class] forCellWithReuseIdentifier:@"AppIconCell"];
    [drawerContainer addSubview:self.collectionView];
    
    self.drawerContainer = drawerContainer;
    self.drawerHeight = drawerHeight;
    
    [self performSelector:@selector(animateIn) withObject:nil afterDelay:0.01];
}

- (void)animateIn {
    [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:0.85 initialSpringVelocity:0.5 options:0 animations:^{
        self.backgroundView.alpha = 1;
        self.drawerContainer.frame = CGRectMake(0, self.view.bounds.size.height - self.drawerHeight, self.view.bounds.size.width, self.drawerHeight);
    } completion:nil];
}

- (void)dismissDrawer {
    [UIView animateWithDuration:0.25 animations:^{
        self.backgroundView.alpha = 0;
        self.drawerContainer.frame = CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, self.drawerHeight);
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
        [self removeFromParent];
        appDrawerVC = nil;
        isAppDrawerVisible = NO;
    }];
    [self.searchBar resignFirstResponder];
}

- (void)loadApplications {
    LSApplicationWorkspace *workspace = [LSApplicationWorkspace defaultWorkspace];
    NSArray *all = [workspace allApplications];
    NSMutableArray *apps = [NSMutableArray array];
    
    for (LSApplicationProxy *app in all) {
        if ([app isHidden] || ![app isUserInstallable] || [app isSystemApp]) continue;
        if ([app.applicationIdentifier hasPrefix:@"com.apple."] && ![app isUserInstallable]) continue;
        [apps addObject:app];
    }
    
    [apps sortUsingComparator:^NSComparisonResult(LSApplicationProxy *a, LSApplicationProxy *b) {
        return [a.localizedName localizedCaseInsensitiveCompare:b.localizedName];
    }];
    
    self.allApps = [apps copy];
    self.filteredApps = self.allApps;
    [self.collectionView reloadData];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.filteredApps.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AppIconCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"AppIconCell" forIndexPath:indexPath];
    LSApplicationProxy *app = self.filteredApps[indexPath.item];
    cell.app = app;
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    LSApplicationProxy *app = self.filteredApps[indexPath.item];
    [[LSApplicationWorkspace defaultWorkspace] openApplicationWithBundleID:app.applicationIdentifier options:@{}];
    [self dismissDrawer];
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchText.length == 0) {
        self.filteredApps = self.allApps;
    } else {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"localizedName CONTAINS[cd] %@", searchText];
        self.filteredApps = [self.allApps filteredArrayUsingPredicate:predicate];
    }
    [self.collectionView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

@end

@interface AppIconCell : UICollectionViewCell
@property (nonatomic, strong) LSApplicationProxy *app;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *label;
@end

@implementation AppIconCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.iconView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        self.iconView.layer.cornerRadius = 14;
        self.iconView.clipsToBounds = YES;
        self.iconView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:self.iconView];
        
        self.label = [[UILabel alloc] initWithFrame:CGRectMake(0, 64, 60, 16)];
        self.label.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.textColor = [UIColor labelColor];
        self.label.numberOfLines = 1;
        self.label.adjustsFontSizeToFitWidth = YES;
        self.label.minimumScaleFactor = 0.7;
        [self.contentView addSubview:self.label];
    }
    return self;
}

- (void)setApp:(LSApplicationProxy *)app {
    _app = app;
    self.iconView.image = [app iconImageWithSize:CGSizeMake(60, 60)];
    self.label.text = app.localizedName;
}

@end

@interface AppDrawerViewController ()
@property (nonatomic, strong) UIView *drawerContainer;
@property (nonatomic, assign) CGFloat drawerHeight;
@end

%hook SBDockView

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self];
    
    if (location.y < -50 && !isAppDrawerVisible) {
        [self showAppDrawer];
        return;
    }
    
    %orig(touches, event);
}

- (void)showAppDrawer {
    if (isAppDrawerVisible) return;
    
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    if (!keyWindow) return;
    
    AppDrawerViewController *drawer = [[AppDrawerViewController alloc] init];
    drawer.view.frame = keyWindow.bounds;
    drawer.modalPresentationStyle = UIModalPresentationOverFullScreen;
    
    UIViewController *rootVC = keyWindow.rootViewController;
    while (rootVC.presentedViewController) {
        rootVC = rootVC.presentedViewController;
    }
    
    [rootVC presentViewController:drawer animated:NO completion:nil];
    appDrawerVC = drawer;
    isAppDrawerVisible = YES;
}

%end

%hook SBHomeScreenViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig(animated);
    
    UISwipeGestureRecognizer *swipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeUp:)];
    swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
    swipeUp.delegate = self;
    [self.view addGestureRecognizer:swipeUp];
}

- (void)handleSwipeUp:(UISwipeGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateRecognized && !isAppDrawerVisible) {
        CGPoint location = [gesture locationInView:self.view];
        if (location.y > self.view.bounds.size.height * 0.7) {
            SBDockView *dock = nil;
            for (UIView *subview in self.view.subviews) {
                if ([NSStringFromClass([subview class]) containsString:@"Dock"]) {
                    dock = (SBDockView *)subview;
                    break;
                }
            }
            if (dock) [dock showAppDrawer];
        }
    }
}

%end