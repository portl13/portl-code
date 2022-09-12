//
//  ArtistListViewController.m
//  postr-ios
//
//  Created by Messia Engineer on 7/7/16.
//  Copyright © 2016 Messia Engineer. All rights reserved.
//

#import "ArtistListViewController.h"
#import "PortlEngine.h"
#import "ArtistListCell.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import <Toast/UIView+Toast.h>
#import "ArtistDetailsViewController.h"
#import "ArtistCollectionCell.h"
#import "BWHorizontalTableViewCell.h"
#import "UIImageView+DGActivityIndicatorView.h"

#define TAG_IMAGEVIEW_ARTIST_BACKGROUND     0x100
#define TAG_LABEL_ARTIST_NAME               0x102
#define TAG_IMAGEVIEW_ARTIST_API_LOGO       0x104

#define EXACT_NAME_PANEL_CELL_HEIGHT        180
#define EXACT_NAME_PANEL_CELL_WIDTH         120
#define EXACT_NAME_PANEL_CELL_SPACE         10

@interface ArtistListViewController () <UICollectionViewDelegate, UICollectionViewDataSource, SWRevealViewControllerDelegate, BWHorizontalTableViewDelegate, BWHorizontalTableViewDataSource> {
    BOOL nextLoading;
    
    BOOL        selectedExactNamesPanel;
    NSInteger   selecedRow;
}

@property (strong, nonatomic) NSArray *artistList;

@property (strong, nonatomic) NSMutableArray   *exactNamesList;
@property (strong, nonatomic) NSMutableArray   *similarNamesList;

@end

@implementation ArtistListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self.textfieldFilter setAttributedPlaceholder:[[NSAttributedString alloc] initWithString:@"Enter artist name..." attributes:@{NSForegroundColorAttributeName:[UIColor colorWithWhite:1 alpha:0.7f]}]];
    
    self.revealViewController.delegate = self;
    
    self.horizontalTableViewForExactNameArtists.delegate = self;
    self.horizontalTableViewForExactNameArtists.dataSource = self;
    
    [self.horizontalTableViewForExactNameArtists setShowsVerticalScrollIndicator:NO];
    [self.horizontalTableViewForExactNameArtists setContentInset:UIEdgeInsetsMake(0, 10, 0, 10)];
    self.horizontalTableViewForExactNameArtists.alwaysBounceVertical = NO;
    
    self.labelNoExactMatches.hidden = YES;
    
    self.collectionViewMain.hidden = YES;
    self.viewExactNameArtistsPanel.hidden = YES;
    self.constraintForSearchViewHeight.constant = 120;
    [self.textfieldFilter becomeFirstResponder];
    
    self.activityIndicatorForLoader.hidden = YES;
    self.viewRemoveText.hidden = YES;
    
    nextLoading = NO;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationItem.title = @"Artists";
    
    UIBarButtonItem *menu = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_nav_menu"] style:UIBarButtonItemStylePlain target:self action:@selector(onMenu)];
    menu.tintColor = [UIColor whiteColor];
    self.navigationItem.leftBarButtonItem = menu;
    
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
        
        self.labelTitleForExactNamesPanel.text = [NSString stringWithFormat:@"%@ Artists", self.textfieldFilter.text];
        self.labelTitleForSimilarNamesPanel.text = [NSString stringWithFormat:@"\"%@\" Similar Matches", self.textfieldFilter.text];
        
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
    
    self.viewLoaderPanel.hidden = NO;
    
    [[PortlEngine engine] startArtistSearch:^(BOOL succeeded, NSArray * _Nullable artists, NSInteger estimatedEventsCount) {
        
        self.viewLoaderPanel.hidden = YES;
        
        if (succeeded) {
            
            self.artistList = artists;
            [self filterArtists];
            [self.collectionViewMain reloadData];
            [self.horizontalTableViewForExactNameArtists reloadData];
            
            self.labelTitleForExactNamesPanel.text = [NSString stringWithFormat:@"%@ Artists(%d)", self.textfieldFilter.text, (int)self.exactNamesList.count];
            
            if (self.exactNamesList.count == 0) {
                self.labelNoExactMatches.hidden = NO;
                self.constraintForExactMatchesListHeight.constant = 30;
            } else {
                self.labelNoExactMatches.hidden = YES;
                self.constraintForExactMatchesListHeight.constant = 180;
                [self.horizontalTableViewForExactNameArtists scrollToColumnAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] animated:NO];
            }
            
            self.viewLoaderPanel.hidden = YES;
            self.collectionViewMain.hidden = NO;
            self.viewExactNameArtistsPanel.hidden = NO;
        }
    } forKeyword:self.textfieldFilter.text];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    CGFloat bottomEdge = scrollView.contentOffset.y + scrollView.frame.size.height;
    
    if (bottomEdge >= scrollView.contentSize.height)
    {
        if (!nextLoading) {
            
            if (![[PortlEngine engine] artistSearchCompleted]) {
                
                nextLoading = YES;
                [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                
                [[PortlEngine engine] loadNextArtists:^(BOOL succeeded, NSArray * _Nullable artists, NSInteger estimatedEventsCount) {
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                    self.artistList = artists;
                    [self filterArtists];
                    [self.collectionViewMain reloadData];
                    [self.horizontalTableViewForExactNameArtists reloadData];
                    self.labelTitleForExactNamesPanel.text = [NSString stringWithFormat:@"%@ Artists(%d)", self.textfieldFilter.text, (int)self.exactNamesList.count];
                    nextLoading = NO;
                    
                    if (self.exactNamesList.count == 0) {
                        self.labelNoExactMatches.hidden = NO;
                        self.constraintForExactMatchesListHeight.constant = 30;
                    } else {
                        self.labelNoExactMatches.hidden = YES;
                        self.constraintForExactMatchesListHeight.constant = 180;
                        [self.horizontalTableViewForExactNameArtists scrollToColumnAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] animated:NO];
                    }
                    
                } forKeyword:self.textfieldFilter.text];
                
            }
        }
    }
    
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



@end
