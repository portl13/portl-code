//
//  ArtistListViewController.h
//  postr-ios
//
//  Created by Messia Engineer on 7/7/16.
//  Copyright © 2016 Messia Engineer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BWHorizontalTableView.h"

@interface SearchViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *textfieldFilter;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintForSearchViewHeight;
@property (weak, nonatomic) IBOutlet UIView *viewLoaderPanel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorForLoader;
@property (weak, nonatomic) IBOutlet UIView *viewRemoveText;

@property (weak, nonatomic) IBOutlet UITableView *tableViewArtists;

@property (weak, nonatomic) IBOutlet UILabel *labelNoResults;
@property (weak, nonatomic) IBOutlet UIView *viewSettingsPopover;


@end
