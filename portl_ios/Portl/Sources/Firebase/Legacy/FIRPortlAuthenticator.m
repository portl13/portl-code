//
//  FIRPortlAuthenticator.m
//  Portl iOS Application
//  Created by Portl LLC on 2017/04/29.
//  Copyright © 2017 Portl LLC. All rights reserved.
//

#import "FIRPortlAuthenticator.h"
#import "NSDictionary+safeString.h"

#define GUEST_LOGIN_AUTH_EMAIL      @"guest@portl.com"

@implementation FIRPortlAuthenticator

static FIRPortlAuthenticator *instance;

+(FIRPortlAuthenticator *)sharedAuthenticator {
    if (instance == nil) {
        instance = [FIRPortlAuthenticator new];
    }
    
    return instance;
}

- (FIRDatabaseReference *)databaseRef {
    return [[FIRDatabase database] reference];
}

- (FIRDatabaseReference *)userProfileRef {
    return [[[self databaseRef] child:@"v2/profile"] child:[[self currentUser] uid]];
}

- (FIRUser *)currentUser {
    return [[FIRAuth auth] currentUser];
}

- (void)checkValidUser:(void(^)(BOOL valid, BOOL availableToCheck))completed {
    if ([self currentUser] == nil) {
        completed(NO, YES);
    } else {
        [[self currentUser] reloadWithCompletion:^(NSError * _Nullable error) {
            if (error == nil) {
                completed(YES, YES);
            } else {
                if (error.code == 500) {
                    completed(NO, NO);
                } else {
                    completed(NO, YES);
                }
            }
        }];
    }
}

- (BOOL)authorized {
    return ([self currentUser] != nil);
}

- (void)guestLoginWithCompleted:(void(^)(PortlError *error))completed {
	[[FIRAuth auth] signInAnonymouslyWithCompletion:^(FIRAuthDataResult * _Nullable authResult, NSError * _Nullable error) {
		NSLog(@"Sign in anonymously");
		if (error == nil) {
			completed(nil);
		} else {
			completed([PortlError errorWithError:error code:0 message:error.localizedDescription]);
		}
	}];
}

- (void)searchEmail:(NSString *)email completed:(void (^)(NSDictionary *user, PortlError *error))completed {
    [[[[[self databaseRef] child:@"v2/profile"] queryOrderedByChild:@"email"] queryEqualToValue:email] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        
        if ([snapshot exists]) {
            
            for (FIRDataSnapshot *child in [[snapshot children] allObjects]) {
                NSDictionary *user = child.value;
                if (user != nil) {
                    if ([[user safeStringForKey:@"email"] isEqualToString:email]) {
                        completed(user, nil);
                        return;
                    }
                }
            }
            completed(nil, [PortlError errorWithError:nil code:999 message:@"Unexpected Error"]);
            
        } else {
            
            completed(nil, nil);
            
        }
        
    } withCancelBlock:^(NSError * _Nonnull error) {
        completed(nil, [PortlError errorWithError:error code:0 message:nil]);
    }];
}

- (void)searchUsername:(NSString *)username completed:(void (^)(NSDictionary *user, PortlError *error))completed {
	[[[[[self databaseRef] child:@"v2/profile"] queryOrderedByChild:@"username_d"] queryEqualToValue:[username lowercaseString]] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
		if ([snapshot exists]) {
			for (FIRDataSnapshot *child in [[snapshot children] allObjects]) {
				NSDictionary *user = child.value;
				if (user != nil) {
					if ([[user safeStringForKey:@"username_d"] isEqualToString:[username lowercaseString]]) {
						completed(user, nil);
						return;
					}
				}
			}
			completed(nil, [PortlError errorWithError:nil code:999 message:@"Unexpected Error"]);
		} else {
			completed(nil, nil);
		}
	} withCancelBlock:^(NSError * _Nonnull error) {
		completed(nil, [PortlError errorWithError:error code:0 message:nil]);
	}];
}

- (BOOL)isGuestLogin {
    if ([self authorized]) {
        return [self currentUser].isAnonymous;
    } else {
        return NO;
    }
}

- (void)loginWithEmail:(NSString *)email withPassword:(NSString *)password completed:(void(^)(PortlError *error))completed {
    
    if ([self isGuestLogin]) {
        [self signOut];
    }
	[[FIRAuth auth] signInWithEmail:email password:password completion:^(FIRAuthDataResult * _Nullable authResult, NSError * _Nullable error) {
		if (error != nil) {
			FIRAuthErrorCode errCode = error.code;
			switch (errCode) {
				case FIRAuthErrorCodeInvalidEmail:
				case FIRAuthErrorCodeUserNotFound:
				case FIRAuthErrorCodeInvalidCredential:
					completed([PortlError errorWithError:error code:PERRCODE_INVALID_EMAIL message:PERR_INVALID_EMAIL]);
					break;
				case FIRAuthErrorCodeWrongPassword:
					completed([PortlError errorWithError:error code:PERRCODE_INVALID_PASSWORD message:PERR_INVALID_PASSWORD]);
					break;
				default:
					completed([PortlError errorWithError:error code:PERRCODE_UNKNOWN_FIREBASE_ERROR message:PERR_UNKNOWN_FIREBASE_ERROR]);
					break;
			}
		} else {
			
			[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"AuthStateChangedNotification" object:nil]];
			[[NSNotificationCenter defaultCenter] postNotificationName:notificationLogin object:nil];
			
			[[[[self databaseRef] child:@"v2/profile"] child:authResult.user.uid] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
				
				if ([snapshot exists]) {
					
					self.authorizedProfile = snapshot.value;
					NSLog(@"Loaded profile - %@", self.authorizedProfile);
					
					if (completed != nil) {
						completed(nil);
					}
					
				} else {
					
					completed([PortlError errorWithError:nil code:PERRCODE_USER_DELETED message:PERR_USER_DELETED]);
					
				}
				
				[self connectProfileObserverWithCompleted];
				
			}];
			
		}
	}];
}

- (void)signupWithEmail:(NSString *)email
			   password:(NSString *)password
			   username:(NSString *)username
            fromGuestId:(NSString *)guestId
              completed:(void(^)(PortlError *error))completed {
    
    // Step 1 : Check if Email address already taken
	
    [self searchEmail:email completed:^(NSDictionary *user, PortlError *error) {
        if (user != nil) {
            completed([PortlError errorWithError:nil code:PERRCODE_EMAIL_ALREADY_TAKEN message:PERR_EMAIL_ALREADY_TAKEN]);
            return;
        }
		
		// Step 2 : Check if Username is already taken
		
		[self searchUsername:username completed:^(NSDictionary *user, PortlError *error) {
			if (user != nil) {
				completed([PortlError errorWithError:nil code:PERRCODE_USERNAME_ALREADY_TAKEN message:PERR_USERNAME_ALREADY_TAKEN]);
				return;
			}
			[[FIRAuth auth] createUserWithEmail:email password:password completion:^(FIRAuthDataResult * _Nullable authResult, NSError * _Nullable error) {
				if (error == nil) {
					if (authResult != nil) {
						NSDictionary *profile = @{@"email":email,
												  @"username":[username stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]],
												  @"username_d": [username lowercaseString],
												  @"uid":authResult.user.uid,
												  @"from_guest":guestId,
												  @"created":[DateUtility stringFromDate:[NSDate date] toFormat:@"yyyy-MM-dd HH:mm:ss z"]};
						
						FIRDatabaseReference *userRef = [[[self databaseRef] child:@"v2/profile"] child:authResult.user.uid];
						[userRef setValue:profile withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
							if (error != nil) {
								completed([PortlError errorWithError:error code:0 message:nil]);
							} else {
								self.authorizedProfile = [profile mutableCopy];
								[self loginWithEmail:email withPassword:password completed:completed];
							}
						}];
					} else {
						completed([PortlError errorWithError:error code:PERRCODE_UNKNOWN_FIREBASE_ERROR message:error.localizedDescription]);
					}
				} else {
					completed([PortlError errorWithError:error code:0 message:error.localizedDescription]);
				}
			}];
		}];
    }];
}

- (void)connectProfileObserverWithCompleted/*:(void(^)(PortlError *error)) completed*/ {
    
    if ([self authorized]) {
        
        [[[[self databaseRef] child:@"v2/profile"] child:self.currentUser.uid] observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            if ([snapshot exists]) {
                self.authorizedProfile = snapshot.value;
                [[NSNotificationCenter defaultCenter] postNotificationName:gNotificationUserProfileUpdated object:nil];
            } else {
                NSLog(@"Could not find profile");
                [[NSNotificationCenter defaultCenter] postNotificationName:gNotificationUserProfileUpdated object:nil];
            }
        }];
    }
}

- (void)loadProfile:(BOOL)withRefresh completed:(void(^)(PortlError *error))completed {
    
    if ([self authorized]) {
        if (!withRefresh && self.authorizedProfile != nil) {
            if (completed != nil) completed(nil);
            return;
        }
        
        [[[[[self databaseRef] child:@"v2/profile"] queryOrderedByChild:@"uid"] queryEqualToValue:self.currentUser.uid] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            
            if ([snapshot exists]) {
                
                for (FIRDataSnapshot *child in [snapshot.children allObjects]) {
                    self.authorizedProfile = [child.value mutableCopy];
					if (completed != nil) completed(nil);
                    return;
                }
            } else {
                if (completed != nil) completed([PortlError errorWithError:nil code:PERRCODE_UNKNOWN_FIREBASE_ERROR message:PERR_UNKNOWN_FIREBASE_ERROR]);
            }
            
        } withCancelBlock:^(NSError * _Nonnull error) {
            if (completed != nil) completed([PortlError errorWithError:error code:PERRCODE_FIREBASE_ACTION_CANCELED message:PERR_FIREBASE_ACTION_CANCELED]);
        }];
        
        return;
        
    } else {
        
        if (completed != nil) completed([PortlError errorWithError:nil code:PERRCODE_NOT_AUTHORIZED message:PERR_NOT_AUTHORIZED]);
        
    }
}

- (void)signOut {
	[[NSNotificationCenter defaultCenter] postNotificationName:notificationLogout object:nil];

    [[[[self databaseRef] child:@"v2/profile"] child:self.currentUser.uid] removeAllObservers];
    
    NSError *error;
    BOOL status = [[FIRAuth auth] signOut:&error];
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"AuthStateChangedNotification" object:nil]];

    if (!status) {
        NSLog(@"Sign out error - %@", error);
    } else {
        NSLog(@"current user signed out");
    }
    
    self.authorizedProfile = nil;
}

- (void)updateProfileBirthday:(NSDate *)birthday {
	if(birthday != nil) {
		[[self userProfileRef] updateChildValues:@{@"birth_date":[DateUtility stringFromDate:birthday toFormat:@"yyyy-MM-dd"]}];
	}
	else {
		[[self userProfileRef] updateChildValues:@{@"birth_date":@""}];
	}
}

- (void)updateMyInterests:(NSArray *)interests completed:(void(^)(PortlError *error))completed {
    [[self userProfileRef] updateChildValues:@{@"interests":interests} withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
        if (completed != nil) {
            if (error == nil) {
                completed(nil);
            } else {
                completed([PortlError errorWithError:error code:0 message:nil]);
            }
        }
    }];
}

- (void)updateProfileGender:(NSString *)gender {
    
    [[self userProfileRef] updateChildValues:@{@"gender":gender}];
    
}

- (void)updateProfileAvatarUrl:(NSString *)avatarUrl {
    [[self userProfileRef] updateChildValues:@{@"avatar":avatarUrl}];
}


@end
