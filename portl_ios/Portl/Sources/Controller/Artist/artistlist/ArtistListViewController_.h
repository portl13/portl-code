//
//  ArtistListViewController.h
//  postr-ios
//
//  Created by Messia Engineer on 7/7/16.
//  Copyright © 2016 Messia Engineer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BWHorizontalTableView.h"

@interface ArtistListViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *textfieldFilter;

//@property (weak, nonatomic) IBOutlet UITableView *tableViewMain;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintForSearchViewHeight;
@property (weak, nonatomic) IBOutlet UIView *viewLoaderPanel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorForLoader;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionViewMain;
@property (weak, nonatomic) IBOutlet UIView *viewRemoveText;

@property (weak, nonatomic) IBOutlet UIView *viewExactNameArtistsPanel;
@property (weak, nonatomic) IBOutlet UILabel *labelTitleForExactNamesPanel;
@property (weak, nonatomic) IBOutlet UILabel *labelTitleForSimilarNamesPanel;
@property (weak, nonatomic) IBOutlet BWHorizontalTableView *horizontalTableViewForExactNameArtists;
@property (weak, nonatomic) IBOutlet UILabel *labelNoExactMatches;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintForExactMatchesListHeight;

@end
