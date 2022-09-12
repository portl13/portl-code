//
//  ArtistListViewController.m
//  postr-ios
//
//  Created by Messia Engineer on 7/7/16.
//  Copyright © 2016 Messia Engineer. All rights reserved.
//

#import "SearchViewController.h"
#import "PortlEngine.h"
#import "ArtistListCell.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import <Toast/UIView+Toast.h>
#import "ArtistDetailsViewController.h"
#import "ArtistCollectionCell.h"
#import "BWHorizontalTableViewCell.h"
#import "UIImageView+DGActivityIndicatorView.h"
#import "VenueListCell.h"
#import "VenueDetailsViewController.h"

#define TAG_IMAGEVIEW_ARTIST_BACKGROUND     0x100
#define TAG_LABEL_ARTIST_NAME               0x102
#define TAG_IMAGEVIEW_ARTIST_API_LOGO       0x104

#define EXACT_NAME_PANEL_CELL_HEIGHT        180
#define EXACT_NAME_PANEL_CELL_WIDTH         120
#define EXACT_NAME_PANEL_CELL_SPACE         10

@interface SearchViewController () <SWRevealViewControllerDelegate,  UITableViewDelegate, UITableViewDataSource> {
    
    BOOL        nextLoading;
    BOOL        selectedExactNamesPanel;
    NSInteger   selecedRow;
    
    int         selectedSearchMode;         // 0 for Artist, 1 for venue
    
}

@property (strong, nonatomic) NSArray *artistList;

@property (strong, nonatomic) NSArray *venues;

@property (strong, nonatomic) NSMutableArray   *exactNamesList;
@property (strong, nonatomic) NSMutableArray   *similarNamesList;

@property (weak, nonatomic) IBOutlet UIView *viewArtistSection;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewArtistCheckmark;

@property (weak, nonatomic) IBOutlet UIView *viewVenueSection;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewVenueCheckMark;

@end

@implementation SearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self.textfieldFilter setAttributedPlaceholder:[[NSAttributedString alloc] initWithString:@"Enter keyword..." attributes:@{NSForegroundColorAttributeName:[UIColor colorWithWhite:1 alpha:0.7f]}]];
    
    self.revealViewController.delegate = self;
    
    self.tableViewArtists.tableFooterView = [UIView new];

    
    self.tableViewArtists.hidden = YES;
    self.labelNoResults.hidden = YES;
    
    self.constraintForSearchViewHeight.constant = 120;
    
    
    [self.textfieldFilter performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.5f];
    
    self.activityIndicatorForLoader.hidden = YES;
    self.viewRemoveText.hidden = YES;
    
    nextLoading = NO;
    
    self.viewSettingsPopover.hidden = YES;
    selectedSearchMode = 0;
    self.imageViewVenueCheckMark.hidden = YES;
    self.imageViewArtistCheckmark.hidden = NO;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationItem.title = @"Search";
    
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_arrow_left"] style:UIBarButtonItemStylePlain target:self action:@selector(onBack)];
    backItem.tintColor = [UIColor whiteColor];
    self.navigationItem.leftBarButtonItem = backItem;
    
    UIBarButtonItem *settingsItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_menu_settings"] style:UIBarButtonItemStylePlain target:self action:@selector(onSettings)];
    settingsItem.tintColor = [UIColor whiteColor];
    self.navigationItem.rightBarButtonItem = settingsItem;
}

- (void) onBack {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) onSettings {
    
    if (!self.viewSettingsPopover.hidden) {
        
        [self closeSettingsPanel];
        
    } else {
    
        self.viewSettingsPopover.hidden = NO;
        self.viewSettingsPopover.alpha = 0;
        [UIView animateWithDuration:0.5f animations:^{
            self.viewSettingsPopover.alpha = 1;
        }];
    }
}

- (IBAction)onCloseSettings:(id)sender {
    [self closeSettingsPanel];
}

- (void)closeSettingsPanel {
    [UIView animateWithDuration:0.5f animations:^{
        self.viewSettingsPopover.alpha = 0;
    } completion:^(BOOL finished) {
        if (finished) {
            self.viewSettingsPopover.hidden = YES;
        }
    }];
}

- (IBAction)onTouchDownOnArtistSection:(id)sender {
    self.viewArtistSection.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.3f];
}

- (IBAction)onTouchUpInsideOnArtistSection:(id)sender {
    self.viewArtistSection.backgroundColor = [UIColor clearColor];
    self.imageViewVenueCheckMark.hidden = YES;
    self.imageViewArtistCheckmark.hidden = NO;
    selectedSearchMode = 0;
}

- (IBAction)onTouchUpOutsideOnArtistSection:(id)sender {
    self.viewArtistSection.backgroundColor = [UIColor clearColor];
}

- (IBAction)onTouchDownOnVenueSection:(id)sender {
    self.viewVenueSection.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.3f];
}

- (IBAction)onTouchUpInsideOnVenueSection:(id)sender {
    self.viewVenueSection.backgroundColor = [UIColor clearColor];
    self.imageViewVenueCheckMark.hidden = NO;
    self.imageViewArtistCheckmark.hidden = YES;
    selectedSearchMode = 1;
}

- (IBAction)onTouchUpOutsideOnVenueSection:(id)sender {
    self.viewVenueSection.backgroundColor = [UIColor clearColor];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([segue.identifier isEqualToString:@"sid_details"]) {
        ArtistDetailsViewController *controller = segue.destinationViewController;
        if (selectedExactNamesPanel) {
            controller.artist = [self.exactNamesList objectAtIndex:selecedRow];
        } else {
            controller.artist = [self.similarNamesList objectAtIndex:selecedRow];
        }
    }
}

- (void)onMenu {
    [self.view endEditing:YES];
    [self.revealViewController revealToggleAnimated:YES];
}

#pragma mark - UICollectionView methods

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.similarNamesList == nil || self.similarNamesList.count == 0) {
        return 1;
    } else {
        return self.similarNamesList.count;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    if (self.similarNamesList == nil || self.similarNamesList.count == 0) {
        return CGSizeMake(collectionView.frame.size.width - 30, 44);
    } else {
        return CGSizeMake((collectionView.frame.size.width - 5) / 3, (collectionView.frame.size.width - 5) / 3 * 4 / 3);
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    
    if (self.similarNamesList == nil || self.similarNamesList.count == 0) {
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"NoSimiliarMatchesCell" forIndexPath:indexPath];
        return cell;
    } else {
        ArtistCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ArtistCollectionCell" forIndexPath:indexPath];
        cell.backgroundColor = [UIColor clearColor];
        [cell configureWithArtist:self.similarNamesList[indexPath.row]];
        return cell;
    }
    
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.similarNamesList != nil && self.similarNamesList.count > 0) {
        selectedExactNamesPanel = NO;
        selecedRow = indexPath.row;
        [self performSegueWithIdentifier:@"sid_details" sender:nil];
    }
}


- (IBAction)onDidEndOnExit:(id)sender {
    
    if ([self.textfieldFilter.text isEqualToString:@""]) {
        
        [self.view makeToast:@"Please enter artist name..."];
        
    } else {
        
        [self.textfieldFilter resignFirstResponder];
        self.activityIndicatorForLoader.hidden = NO;
        [self.activityIndicatorForLoader startAnimating];
        self.constraintForSearchViewHeight.constant = 44;
        
//        self.labelTitleForExactNamesPanel.text = [NSString stringWithFormat:@"%@ Artists", self.textfieldFilter.text];
//        self.labelTitleForSimilarNamesPanel.text = [NSString stringWithFormat:@"\"%@\" Similar Matches", self.textfieldFilter.text];
        
        [UIView animateWithDuration:0.5f animations:^{
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            [self startSearch];
        }];
        
    }
}

#pragma mark - SWRevealViewController methods
- (void)revealController:(SWRevealViewController *)revealController willMoveToPosition:(FrontViewPosition)position {
    static NSInteger tagLockView = 4207868612;
    
    if (revealController.frontViewPosition == FrontViewPositionLeft) {
        
        UIView *lock = [[UIView alloc] initWithFrame:self.revealViewController.frontViewController.view.bounds];
        lock.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        lock.tag = tagLockView;
        lock.backgroundColor = [UIColor blackColor];
        lock.alpha = 0;
        
        @try {
            [lock addGestureRecognizer:[self.revealViewController panGestureRecognizer]];
        }
        @catch (NSException *exception) {
        }
        @finally {
        }
        
        if (position == FrontViewPositionRight) {
            [lock addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self.revealViewController action:@selector(revealToggle:)]];
        }
        
        [self.revealViewController.frontViewController.view addSubview:lock];
        
        [UIView animateWithDuration:0.75 animations:^{
            lock.alpha = 0.333;
        } completion:^(BOOL finished) {
            
        }];
        
    } else if (revealController.frontViewPosition == FrontViewPositionRight) {
        
        UIView *lock = [self.revealViewController.frontViewController.view viewWithTag:tagLockView];
        [UIView animateWithDuration:0.25 animations:^{
            lock.alpha = 0;
        } completion:^(BOOL finished) {
            [lock removeFromSuperview];
            @try {
                [self.view addGestureRecognizer:[self.revealViewController panGestureRecognizer]];
            } @catch (NSException *ex) {
                
            }
        }];
        
    }
}

- (void)startSearch {
    if (selectedSearchMode == 0) {
        [self startArtistSearch];
    } else {
        [self startVenueSearch];
    }
}

- (void)startVenueSearch {
    
    self.viewLoaderPanel.hidden = NO;
    
    [[PortlEngine engine] startVenuesSearch:^(BOOL succeeded, NSArray * _Nullable venues, NSInteger estimatedEventsCount) {
        if (succeeded) {
            
            self.venues = venues;
            [self sortVenues];
            [self.tableViewArtists reloadData];
            
            self.viewLoaderPanel.hidden = YES;
            self.tableViewArtists.hidden = NO;
            self.labelNoResults.hidden = YES;
        } else {
            self.labelNoResults.hidden = NO;
        }
    } forKeyword:self.textfieldFilter.text];
}

- (void)startArtistSearch {
    
    self.viewLoaderPanel.hidden = NO;
    
    [[PortlEngine engine] startArtistSearch:^(BOOL succeeded, NSArray * _Nullable artists, NSInteger estimatedEventsCount) {
        
        self.viewLoaderPanel.hidden = YES;
        
        if (succeeded) {
            
            self.artistList = artists;
            [self initializeCount];
            [self filterArtists];
            
            if (self.exactNamesList.count > 0) {
                self.tableViewArtists.hidden = NO;
                self.labelNoResults.hidden = YES;
            } else {
                self.tableViewArtists.hidden = YES;
                self.labelNoResults.hidden = NO;
            }
            
            [self.tableViewArtists reloadData];
            
            [self loadEventsCount];
            
            self.viewLoaderPanel.hidden = YES;
            self.tableViewArtists.hidden = NO;

        }
    } forKeyword:self.textfieldFilter.text];
}

- (IBAction)onEditingChangedOnInput:(id)sender {
    if (self.textfieldFilter.text.length > 0) {
        self.viewRemoveText.hidden = NO;
    } else {
        self.viewRemoveText.hidden = YES;
    }
}

- (IBAction)onRemoveText:(id)sender {
    self.textfieldFilter.text = @"";
    [self.textfieldFilter becomeFirstResponder];
    self.viewRemoveText.hidden = YES;
}

- (void) filterArtists {
    
    self.exactNamesList = [NSMutableArray new];
    self.similarNamesList = [NSMutableArray new];
    
    if (self.artistList) {
        
        for (NSInteger idx = self.artistList.count - 1; idx >= 0; idx--) {
            
            PortlArtist *artist = [self.artistList objectAtIndex:idx];
            NSString *artistName = artist.artistName;
            if ([PortlUtils matchArtistNames:artistName withName:self.textfieldFilter.text]) {
                [self.exactNamesList addObject:artist];
            } else {
                [self.similarNamesList addObject:artist];
            }
            
        }
        
    }
    
}

#pragma mark - BWHorizontalTableView methods

- (NSInteger)numberOfSectionsInHorizontalTableView:(BWHorizontalTableView *)tableView {
    return 1;
}

- (NSInteger)horizontalTableView:(BWHorizontalTableView *)tableView numberOfColumnsInSection:(NSInteger)section {
    if (self.exactNamesList == nil) {
        return 0;
    } else {
        return self.exactNamesList.count;
    }
}

- (CGFloat)horizontalTableView:(BWHorizontalTableView *)tableView widthForColumnAtIndexPath:(NSIndexPath *)indexPath {
    return EXACT_NAME_PANEL_CELL_WIDTH + EXACT_NAME_PANEL_CELL_SPACE;
}

- (CGRect)rectForColumnAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return CGRectMake(0, 0, EXACT_NAME_PANEL_CELL_WIDTH, EXACT_NAME_PANEL_CELL_HEIGHT);
}

- (BWHorizontalTableViewCell *)horizontalTableView:(BWHorizontalTableView *)tableView cellForColumnAtIndexPath:(NSIndexPath *)indexPath {
    BWHorizontalTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EventItemCell"];
    if (!cell) {
        cell = [[BWHorizontalTableViewCell alloc] initWithReuseIdentifier:@"EventItemCell"];
        [self initSubViewCell:cell];
    }
    
    [self configureWithItem:[self.exactNamesList objectAtIndex:indexPath.row] forCell:cell];
    return cell;
}

- (void)horizontalTableView:(BWHorizontalTableView *)tableView didSelectColumnAtIndexPath:(NSIndexPath *)indexPath {
    selectedExactNamesPanel = YES;
    selecedRow = indexPath.row;
    [self performSegueWithIdentifier:@"sid_details" sender:nil];
}

- (void)initSubViewCell:(BWHorizontalTableViewCell *)cell {
    
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, EXACT_NAME_PANEL_CELL_WIDTH, EXACT_NAME_PANEL_CELL_HEIGHT)];
    container.backgroundColor = [UIColor colorWithHexValue:0x333333];
    
    UIImageView *imageViewEventBackground = [[UIImageView alloc] initWithFrame:CGRectMake(2, 2, EXACT_NAME_PANEL_CELL_WIDTH - 4, EXACT_NAME_PANEL_CELL_HEIGHT - 4)];
    imageViewEventBackground.contentMode = UIViewContentModeScaleAspectFill;
    imageViewEventBackground.clipsToBounds = YES;
    imageViewEventBackground.tag = TAG_IMAGEVIEW_ARTIST_BACKGROUND;
    [container addSubview:imageViewEventBackground];
    
    UIImageView *imageViewFrame = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg_event_card_frame"]];
    imageViewFrame.frame = CGRectMake(2, 2, EXACT_NAME_PANEL_CELL_WIDTH - 4, EXACT_NAME_PANEL_CELL_HEIGHT - 4);
    imageViewFrame.tag = 0x101;
    [container addSubview:imageViewFrame];
    
    UILabel *labelEventTitle = [[UILabel alloc] initWithFrame:CGRectMake(5, EXACT_NAME_PANEL_CELL_HEIGHT - 40, EXACT_NAME_PANEL_CELL_WIDTH - 10, 40)];
    labelEventTitle.font = [UIFont fontWithName:@"HelveticaNeue-CondensedBold" size:20];
    labelEventTitle.numberOfLines = 2;
    labelEventTitle.textColor = [UIColor whiteColor];
    labelEventTitle.text = @"";
    labelEventTitle.tag = TAG_LABEL_ARTIST_NAME;
    [container addSubview:labelEventTitle];
    
    UIImageView *imageViewAPILogo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[PortlUtils logoImageNameForAPIType:sourceSongKick withSize:@"15"]]];
    imageViewAPILogo.frame = CGRectMake(10, 10, 16, 16);
    imageViewAPILogo.tag = TAG_IMAGEVIEW_ARTIST_API_LOGO;
    [container addSubview:imageViewAPILogo];
    
    [cell addSubview:container];
    
}

- (void)configureWithItem:(PortlArtist *)artist forCell:(BWHorizontalTableViewCell *)cell {
    
    UILabel *labelTitle = [cell viewWithTag:TAG_LABEL_ARTIST_NAME];
    labelTitle.text = artist.artistName;
    
    UIImageView *artistImageView = [cell viewWithTag:TAG_IMAGEVIEW_ARTIST_BACKGROUND];
    if (artist.artistLogo) {
        if (artist.artistLogo.usingDefaultImage) {
            artistImageView.image = [UIImage imageNamed:[PortlUtils thumbForDefaultCover:artist.artistLogo.defaultCoverImage]];
        } else {
            [artistImageView sd_setImageWithURL:[artist.artistLogo coverImageURL] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                
                if (error || ![PortlUtils checkIfImage:image]) {
                    artist.artistLogo.usingDefaultImage = YES;
                    artist.artistLogo.defaultCoverImage = [PortlUtils loadDefaultImageCover];
                    artistImageView.image = [UIImage imageNamed:[PortlUtils thumbForDefaultCover:artist.artistLogo.defaultCoverImage]];
                }
                
            } usingDGActivityIndicatorView:nil];
        }
        
    } else {
        
        artist.artistLogo = [PortlImage imageWithDefaultImage:[PortlUtils loadDefaultImageCover]];
        artistImageView.image = [UIImage imageNamed:[PortlUtils thumbForDefaultCover:artist.artistLogo.defaultCoverImage]];
        
    }
    
    UIImageView *artistLogoView = (UIImageView *)[cell viewWithTag:TAG_IMAGEVIEW_ARTIST_API_LOGO];
    artistLogoView.image = [UIImage imageNamed:[PortlUtils logoImageNameForAPIType:[artist sourceType] withSize:@"15"]];
    
}

#pragma mark - UITableView methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (selectedSearchMode == 0) {
        
        if (self.exactNamesList != nil) {
            return self.exactNamesList.count;
        } else {
            return 0;
        }
        
    } else {
    
        if (self.venues == nil) {
            return 0;
        }
        return self.venues.count;
        
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (selectedSearchMode == 0) {
    
        ArtistListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ArtistListCell"];
        
        [cell configureWithArtist:self.exactNamesList[indexPath.row]];
        return cell;
        
    } else {
        VenueListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VenueCell"];
        [cell configureWithVenue:self.venues[indexPath.row]];
        return cell;
    }
    
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 90;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (selectedSearchMode == 0) {
        if (self.exactNamesList != nil && self.exactNamesList.count > 0) {
            ArtistDetailsViewController *controller = __Controller(@"artist", @"ArtistDetailsViewController");
            controller.artist = [self.exactNamesList objectAtIndex:indexPath.row];
            [self.navigationController pushViewController:controller animated:YES];
        }
    } else {
        VenueDetailsViewController *controller = __Controller(@"venue", @"VenueDetailsViewController");
        controller.venue = [self.venues objectAtIndex:indexPath.row];
        [self.navigationController pushViewController:controller animated:YES];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
}

- (void)initializeCount {
    for (PortlArtist *artist in self.artistList) {
        artist.upcomingEventsCount = -1;
        artist.pastEventsCount = -1;
    }
}

- (void)loadEventsCount {
    for (int idx = 0; idx < self.exactNamesList.count; idx++) {
        PortlArtist *artist = self.exactNamesList[idx];
        if (artist.upcomingEventsCount == -1) {
            [[PortlEngine engine] loadEventsCountForArtist:artist callback:^(int upcoming, int past, PortlArtist *callbackArtist) {
                
                for (int idx = 0; idx < self.exactNamesList.count; idx++) {
                    PortlArtist *artist = self.exactNamesList[idx];
                    if ([callbackArtist.artistId.eventIdentifierOnSource isEqualToString:artist.artistId.eventIdentifierOnSource]) {
                        artist.upcomingEventsCount = upcoming;
                        artist.pastEventsCount = past;
                        [self.tableViewArtists reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
                        return;
                    }
                }
                
            }];
        }
    }
}

- (void)sortVenues {
    self.venues = [self.venues sortedArrayUsingComparator:^NSComparisonResult(PortlVenue *  _Nonnull venue1, PortlVenue *  _Nonnull venue2) {
        
        CLLocation *myLocation;
        if (USING_TEST_LOCATION > 0) {
            myLocation = TEST_CLLOCATION;
        } else {
            if ([[DataKeeper keeper] getDeviceLocation]) {
                myLocation = [[DataKeeper keeper] getDeviceLocation];
            } else {
                myLocation = TEST_CLLOCATION;
            }
        }
        
        CLLocation *location1 = venue1.venueAddress.addressLocation;
        CLLocationDistance distance1 = [location1 distanceFromLocation:myLocation];
        CLLocation *location2 = venue2.venueAddress.addressLocation;
        CLLocationDistance distance2 = [location2 distanceFromLocation:myLocation];
        
        return [[NSNumber numberWithDouble:distance1] compare:[NSNumber numberWithDouble:distance2]];
    }];
}

@end
