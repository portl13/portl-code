//
//  FavoritesHomeViewController.m
//  Portl iOS Application
//  Created by Portl LLC on 2017/04/20.
//  Copyright © 2017 Portl LLC. All rights reserved.
//

#import "FavoritesHomeViewController.h"
#import "Portl-Swift.h"

@interface FavoritesHomeViewController () <UICollectionViewDelegate, UICollectionViewDataSource> {
	BOOL isEditing;
	NSMutableArray *selectedRows;
}
	
	@property (weak, nonatomic) IBOutlet UICollectionView *collectionViewFavoriteEvents;
	@property (strong, nonatomic) UIBarButtonItem *editBarButtonItem;
	
	@property (weak, nonatomic) IBOutlet UILabel *labelSelectEvents;
	@property (weak, nonatomic) IBOutlet UIView *viewActionsPanel;
	@property (weak, nonatomic) IBOutlet UIButton *buttonRemoveEvents;
	@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintForActionViewHeight;
	@property (weak, nonatomic) IBOutlet UILabel *labelNoEvents;
	@property (weak, nonatomic) IBOutlet UIActivityIndicatorView* spinner;
	
	@property (strong, nonatomic) FavoritesController* favoritesController;
	@end

@implementation FavoritesHomeViewController
	
- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view.
	
	self.favoritesController = [[FavoritesController alloc] init];
	[self.collectionViewFavoriteEvents registerNib:[UINib nibWithNibName:@"EventCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"EventCollectionViewCell"];
}
	
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.navigationItem.title = @"Bookmarks";
	
	self.viewActionsPanel.hidden = YES;
	self.constraintForActionViewHeight.constant = 0;
	
	[self.spinner startAnimating];
	
	[self.favoritesController getAuthUserFavoriteEventsWithCompletion:^(NSError * error) {
		if (error != nil) {
			[self presentErrorAlertWithMessage:nil completion:nil];
		}
		[self.collectionViewFavoriteEvents reloadData];
		[self.spinner stopAnimating];
		self.labelNoEvents.hidden = !(self.favoritesController.favoritesCount == 0);
	}];
}
	
#pragma mark - UICollectionView methods
	
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return 1;
}
	
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return self.favoritesController.favoritesCount;
}
	
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
	return CGSizeMake((collectionView.frame.size.width - 5) / 2, (collectionView.frame.size.width - 5) / 2 * 4 / 3);
}
	
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	EventCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"EventCollectionViewCell" forIndexPath:indexPath];
	PortlEvent* event = self.favoritesController.favoriteEvents[indexPath.row];
	[cell configureForEvent:event withMeters:[self.favoritesController getDistanceInMetersFromEvent:event]];
	
	return cell;
	
}
	
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	EventDetailsViewController *controller = __Controller(@"event", @"EventDetailsViewController");
	controller.event = self.favoritesController.favoriteEvents[indexPath.row];
	[self.navigationController pushViewController:controller animated:YES];
}
	
- (void)removeRowFor:(NSInteger)row {
	if (selectedRows == nil) return;
	for (NSNumber *number in selectedRows) {
		if (row == [number integerValue]) {
			[selectedRows removeObject:number];
			return;
		}
	}
}
	
- (BOOL)rowSelectedFor:(NSInteger)row {
	if (selectedRows == nil) return NO;
	for (NSNumber *number in selectedRows) {
		if (row == [number integerValue]) {
			return YES;
		}
	}
	return NO;
}
	
	@end
