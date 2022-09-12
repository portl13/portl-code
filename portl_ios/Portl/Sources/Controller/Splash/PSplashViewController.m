//
//  PSplashViewController.m
//  Portl iOS Application
//
//  Created by Portl LLC on 6/9/16.
//  Copyright © 2016 Portl LLC. All rights reserved.
//

#import "PSplashViewController.h"
#import "PLoginViewController.h"
#import "RootTabBarController.h"
#import "Portl-Swift.h"
#import "NSMutableDictionary+safeString.h"

@interface PSplashViewController ()

@end

@implementation PSplashViewController {
	FriendsController* friendsController;
	FCMTokenManagerController* fcmTokenManagerController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	friendsController = [[FriendsController alloc] init];
	fcmTokenManagerController = [[FCMTokenManagerController alloc] init];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self processPostrAnimation];
}

- (void)processPostrAnimation {
    [self initAndShowLoadingIndicator];
    [self processInitialize];
}

- (void)initAndShowLoadingIndicator {
    [self.loadingSpinner startAnimating];
}

- (void)processInitialize {
    if ([[FIRPortlAuthenticator sharedAuthenticator] authorized]) {
        [[FIRPortlAuthenticator sharedAuthenticator] checkValidUser:^(BOOL valid, BOOL availableToCheck) {
            
            if (!valid) {
                if (availableToCheck) {
                    [[FIRPortlAuthenticator sharedAuthenticator] signOut];
                }
                [self onLogin];
            } else {
				[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"AuthStateChangedNotification" object:nil]];
                [[FIRPortlAuthenticator sharedAuthenticator] connectProfileObserverWithCompleted];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProfileConnected) name:gNotificationUserProfileUpdated object:nil];
            }
        }];
    } else {
        [self onLogin];
    }
}

- (void)onProfileConnected {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (![[FIRPortlAuthenticator sharedAuthenticator] isGuestLogin] && [[[FIRPortlAuthenticator sharedAuthenticator].authorizedProfile safeStringForKey:@"email"] isEqualToString:@""]) {
        [[FIRPortlAuthenticator sharedAuthenticator] signOut];
        [self onLogin];
    } else {
        [self onMain];
    }
}

- (void)onLogin {
    PLoginViewController *loginViewController = __Controller(@"login", @"PLoginViewController");
    [self.navigationController pushViewController:loginViewController animated:NO];
}

- (void)onMain {
	[friendsController loadFriends];
	
    [[FIRFriends sharedFriends] fetchMyFriends];
	[fcmTokenManagerController setFCMTokenAfterLogin];

    RootTabBarController *controller = __Controller(@"Main", @"RootTabBarController");
    [self.navigationController pushViewController:controller animated:NO];
    
}

@end
