//
//  RootTabBarController.m
//  Portl iOS Application
//  Created by Portl LLC on 2017/04/11.
//  Copyright © 2017 Portl LLC. All rights reserved.
//

#import "RootTabBarController.h"
#import "FIRFriends.h"
#import "FIRPortlAuthenticator.h"
#import "Portl-Swift.h"

typedef enum {
	HomeIndex = 0,
	InterestedIndex,
	MessagesIndex,
	ConnectIndex,
	LivefeedIndex,
	IndexCount
} NavControllerTabIndex;

@interface RootTabBarController ()

@property (strong, nonatomic) UIView *toggleView;
@property (strong, nonatomic) UIImageView *toggleImageView;
@property (strong, nonatomic) FirebaseUtilsController* firebaseUtilsController;
@property (strong, nonatomic) ProfileServiceController* profileServiceController;

@end

@implementation RootTabBarController {
	BOOL shouldCheckFirebaseSchemaVersion;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (self) {
		self.firebaseUtilsController = [[FirebaseUtilsController alloc] init];
		shouldCheckFirebaseSchemaVersion = true;
		self.profileServiceController = [[ProfileServiceController alloc] init];
	}
	return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self configureTabs];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRefreshFriendsBadge) name:gNotificationFriendListUpdated object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRefreshNotificationsBadge:) name:gNotificationNotificationListUpdated object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRefreshMessagesBadge:) name:gNotificationMessageRoomsUpdated object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateViewControllersForAuthenticationStateChange) name:notificationLogin object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openFriends:) name:gNotificationOpenMyFriends object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedApiDeprecationWarning:) name:gNotificationApiDeprecation object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openDirectMessage:) name:gNotificationOpenDirectMessage object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openEventDetail:) name:gNotificationOpenEventDetail object:nil];
	
	[self.profileServiceController getLivefeedNotificationCount];
	//[self.profileServiceController getUn]
}

	- (void)didReceiveMemoryWarning {
		[super didReceiveMemoryWarning];
		// Dispose of any resources that can be recreated.
		[[NSNotificationCenter defaultCenter] removeObserver:self];
	}

-(void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	if (shouldCheckFirebaseSchemaVersion) {
		shouldCheckFirebaseSchemaVersion = NO;
		[self.firebaseUtilsController isFirebaseSchemaDeprecatedWithCompletion:^(NSString * result) {
			if (result != nil) {
				[self presentErrorAlertWithMessage:result completion:nil];
			}
		}];
	}
}

- (void)configureTabs {
	UIColor* badgeColor = [UIColor colorWithRed:237.0/255.0 green:30.0/255.0 blue:121.0/255.0 alpha:1.0];
	
	UINavigationController *homeScene = __Controller(@"home", @"HomeScene");
    homeScene.tabBarItem.title = @"Home";
    homeScene.tabBarItem.image = [UIImage imageNamed:@"icon_tab_bar_home"];
	
    UINavigationController *messagesScene = [[UINavigationController alloc] initWithRootViewController:[self viewControllerForTabIndex:MessagesIndex]];
    messagesScene.tabBarItem.title = @"Messages";
    messagesScene.tabBarItem.image = [UIImage imageNamed:@"icon_tab_bar_messages"];
	messagesScene.tabBarItem.badgeColor = badgeColor;

	UINavigationController *searchScene = [[UINavigationController alloc] initWithRootViewController:[self viewControllerForTabIndex:InterestedIndex]];
    searchScene.tabBarItem.title = @"Bookmarks";
    searchScene.tabBarItem.image = [UIImage imageNamed:@"icon_tab_bar_bookmarks"];
	
	UINavigationController* connectScene = [[UINavigationController alloc] initWithRootViewController:[self viewControllerForTabIndex:ConnectIndex]];
	connectScene.tabBarItem.title = @"Connect";
	connectScene.tabBarItem.image = [UIImage imageNamed:@"icon_tab_bar_connect"];
	connectScene.tabBarItem.badgeColor = badgeColor;

    UINavigationController *livefeedScene = [[UINavigationController alloc] initWithRootViewController:[self viewControllerForTabIndex:LivefeedIndex]];
    livefeedScene.tabBarItem.title = @"Livefeed";
    livefeedScene.tabBarItem.image = [UIImage imageNamed:@"icon_tab_bar_livefeed"];
	livefeedScene.tabBarItem.badgeColor = badgeColor;

    self.viewControllers = @[homeScene, searchScene, messagesScene, connectScene, livefeedScene];
	
    self.tabBar.unselectedItemTintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5f];
    self.tabBar.backgroundColor = [UIColor clearColor];
    self.tabBar.tintColor = [UIColor whiteColor];
    self.tabBar.shadowImage = [UIImage new];
    self.tabBar.clipsToBounds = YES;
}

- (void)updateViewControllersForAuthenticationStateChange {
	for (int i = InterestedIndex; i < IndexCount; i++) {
		UINavigationController* nav = self.viewControllers[i];
		nav.viewControllers = @[[self viewControllerForTabIndex:i]];
	}
}

- (UIViewController*)viewControllerForTabIndex:(NavControllerTabIndex)idx {
	BOOL authenticated = [[FIRPortlAuthenticator sharedAuthenticator] authorized] && ![[FIRPortlAuthenticator sharedAuthenticator] isGuestLogin];
	
	UIViewController* controller = authenticated ? [self authenticatedViewControllerForTabIndex:idx] : [self nonAuthenticatedViewControllerForTabIndex:idx];
	
	return controller;
}

	- (UIViewController*)authenticatedViewControllerForTabIndex:(NavControllerTabIndex)idx {
		switch (idx) {
			case HomeIndex:
			break;
			case InterestedIndex:
				return __Controller(@"favorite", @"FavoritesHomeViewController");
			break;
			case MessagesIndex:
				return __Controller(@"message", @"MessagesHomeViewController");
			break;
			case ConnectIndex:
				return __Controller(@"connect", @"ConnectHomeViewController");
			break;
			case LivefeedIndex:
				return __Controller(@"notification", @"LivefeedListViewController");
			default:
			break;
		}
		
		return [[UIViewController alloc] init];
	}
	
	- (UIViewController*)nonAuthenticatedViewControllerForTabIndex:(NavControllerTabIndex)idx {
		AuthRequiredViewController* controller = __Controller(@"common", @"AuthRequiredViewController");
		switch (idx) {
			case HomeIndex:
			break;
			case InterestedIndex:
				[controller setMessage:@"You must sign in to manage your interested events."];
				[controller setTitle:@"Interested"];
				break;
			case MessagesIndex:
				[controller setMessage:@"You must sign in to send or receive messages."];
				[controller setTitle:@"Messages"];
				break;
			case ConnectIndex:
				[controller setMessage:@"You must sign in to manage your connections."];
				[controller setTitle:@"Connect"];
				break;
			case LivefeedIndex:
				[controller setMessage:@"You must sign in to view your livefeed."];
				[controller setTitle:@"Livefeed"];
				break;
			default:
			break;
		}
		return controller;
	}
	
- (void)presentViewController:(UIViewController *)controller {
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)dismissViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onRefreshFriendsBadge {
    if ([[FIRFriends sharedFriends] friendsCountWaitingForAcceptance] > 0) {
        self.viewControllers[3].tabBarItem.badgeValue = [NSString stringWithFormat:@"%d", [[FIRFriends sharedFriends] friendsCountWaitingForAcceptance]];
    } else {
        self.viewControllers[3].tabBarItem.badgeValue = nil;
    }
}

- (void)onRefreshNotificationsBadge: (NSNotification*)notification {
	NSDictionary* userInfo = notification.userInfo;
	if (userInfo[@"count"] != nil) {
		long count = ((NSNumber*)userInfo[@"count"]).longValue;
		if (count > 0) {
			self.viewControllers[4].tabBarItem.badgeValue = [NSString stringWithFormat:@"%ld", count];
		} else {
			self.viewControllers[4].tabBarItem.badgeValue = nil;
		}
	} else {
		self.viewControllers[4].tabBarItem.badgeValue = nil;
	}
}

- (void)onRefreshMessagesBadge: (NSNotification*)notification {
	NSDictionary* userInfo = notification.userInfo;
	if (userInfo[@"count"] != nil) {
		long count = ((NSNumber*)userInfo[@"count"]).longValue;
		if (count > 0) {
			self.viewControllers[2].tabBarItem.badgeValue = [NSString stringWithFormat:@"%ld", count];
		} else {
			self.viewControllers[2].tabBarItem.badgeValue = nil;
		}
	} else {
		self.viewControllers[2].tabBarItem.badgeValue = nil;
	}
}

- (void)receivedApiDeprecationWarning: (NSNotification*)notification {
	NSDictionary* userInfo = notification.userInfo;
	NSString* message = userInfo[@"message"];
	[self presentErrorAlertWithMessage:message completion:nil];
}

- (void)openFriends: (NSNotification*)notification {
	NSDictionary* userInfo = notification.userInfo;

	UINavigationController* controller = self.viewControllers[ConnectIndex];
	[controller popToRootViewControllerAnimated:NO];
	ConnectHomeViewController* connect = controller.viewControllers[0];
	connect.segmentIndex = 1;
	if (userInfo != nil && userInfo[@"show_notifications"] != nil) {
		connect.showNotificationsOnAppear = true;
	}
	[self setSelectedIndex:3];
}

- (void)openDirectMessage: (NSNotification*)notification {
	NSDictionary* userInfo = notification.userInfo;
	NSString* username = userInfo[@"username"];
	NSString* conversationKey = userInfo[@"conversationKey"];
	UINavigationController* controller = self.viewControllers[MessagesIndex];
	[controller popToRootViewControllerAnimated:NO];
	DirectConversationViewController* dm = __Controller(@"message", @"DirectConversationViewController");
	dm.username = username;
	dm.conversationKey = conversationKey;
	[controller pushViewController:dm animated:NO];
	[self setSelectedIndex:2];
}

- (void)openEventDetail: (NSNotification*)notification {
	NSDictionary* userInfo = notification.userInfo;
	PortlEvent* event = userInfo[@"event"];
	
	UINavigationController* controller = self.viewControllers[HomeIndex];
	[controller popToRootViewControllerAnimated:NO];
	EventDetailsViewController* ed = __Controller(@"event", @"EventDetailsViewController");
	ed.event = event;
	
	[self setSelectedIndex:0];
	[controller pushViewController:ed animated:YES];
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
	if([item.title isEqualToString:@"Home"]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:gNotificationHomeButtonPressed object:self];
	}
}

@end
