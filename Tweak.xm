
%config(nonfragile-ivars);

#import <SpringBoard/SpringBoard.h>
#import <SpringBoardFoundation/SpringBoardFoundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

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

@interface AppDrawerViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UISearchBarDelegate>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) NSArray *allApps;
@property (nonatomic, strong) NSArray *filteredApps;
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIView *drawerContainer;
@property (nonatomic, assign) CGFloat drawerHeight;
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
    
    self.drawerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, drawerY, self.view.bounds.size.width, drawerHeight)];
    self.drawerContainer.backgroundColor = [UIColor systemBackgroundColor];
    self.drawerContainer.layer.cornerRadius = 24;
    self.drawerContainer.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    self.drawerContainer.layer.shadowColor = [UIColor blackColor].CGColor;
    self.drawerContainer.layer.shadowOpacity = 0.3;
    self.drawerContainer.layer.shadowRadius = 20;
    self.drawerContainer.layer.shadowOffset = CGSizeMake(0, -5);
    [self.view addSubview:self.drawerContainer];
    self.drawerHeight = drawerHeight;
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(16, 16, self.drawerContainer.bounds.size.width - 32, 44)];
    self.searchBar.delegate = self;
    self.searchBar.placeholder = @"Search apps...";
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.backgroundColor = [UIColor secondarySystemBackgroundColor];
    self.searchBar.layer.cornerRadius = 12;
    self.searchBar.clipsToBounds = YES;
    [self.drawerContainer addSubview:self.searchBar];
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(60, 80);
    layout.minimumInteritemSpacing = 16;
    layout.minimumLineSpacing = 20;
    layout.sectionInset = UIEdgeInsetsMake(16, 20, 20, 20);
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 70, self.drawerContainer.bounds.size.width, self.drawerContainer.bounds.size.height - 70) collectionViewLayout:layout];
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.showsVerticalScrollIndicator = NO;
    [self.collectionView registerClass:[AppIconCell class] forCellWithReuseIdentifier:@"AppIconCell"];
    [self.drawerContainer addSubview:self.collectionView];
    
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
        [self dismissViewControllerAnimated:NO completion:nil];
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
    
    [apps sortUsingComparator:^NSComparisonResult(id a, id b) {
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

- (void)
