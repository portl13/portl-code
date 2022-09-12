//
//  FIRPortlAuthenticator.h
//  Portl iOS Application
//  Created by Portl LLC on 2017/04/29.
//  Copyright © 2017 Portl LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FirebaseAuth/FirebaseAuth.h>
#import <FirebaseDatabase/FirebaseDatabase.h>
#import "Constants.h"
#import "PortlError.h"

#define LOG_TAG_FIREBASE            @"FIR LOG : "
#define notificationLogin 			@"loginNotification"
#define notificationLogout			@"logoutNotification"

@interface FIRPortlAuthenticator : NSObject

+(FIRPortlAuthenticator *)sharedAuthenticator;

@property (strong, nonatomic) NSMutableDictionary *authorizedProfile;

@property (strong, nonatomic) NSArray              *myCreatedVenues;
@property (strong, nonatomic) NSArray              *myCreatedArtists;

- (FIRDatabaseReference *)databaseRef;
- (FIRUser *)currentUser;
- (BOOL)authorized;
- (void)checkValidUser:(void(^)(BOOL valid, BOOL unavailableToCheck))completed;

- (void)guestLoginWithCompleted:(void(^)(PortlError *error))completed;

- (void)loginWithEmail:(NSString *)email withPassword:(NSString *)password completed:(void(^)(PortlError *error))completed;

- (void)signupWithEmail:(NSString *)email
			   password:(NSString *)password
			   username:(NSString *)username
			fromGuestId:(NSString *)guestId
			  completed:(void(^)(PortlError *error))completed;

- (BOOL)isGuestLogin;

- (void)connectProfileObserverWithCompleted/*:(void(^)(PortlError *error)) completed*/;

- (void)signOut;

- (void)updateProfileBirthday:(NSDate *)birthday;
- (void)updateProfileLocationSettings:(NSString *)settings;
- (void)updateProfileGender:(NSString *)gender;
- (void)updateMyInterests:(NSArray *)interests completed:(void(^)(PortlError *error))completed;

@end
