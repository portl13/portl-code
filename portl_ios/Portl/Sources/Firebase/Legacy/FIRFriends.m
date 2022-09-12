//
//  FIRFriends.m
//  Portl iOS Application
//  Created by Portl LLC on 2017/05/02.
//  Copyright © 2017 Portl LLC. All rights reserved.
//

#import "FIRFriends.h"
#import <FirebaseDatabase/FirebaseDatabase.h>
#import "PortlError.h"
#import "Portl-Swift.h"
#import "NSDictionary+safeString.h"
#import "NSMutableDictionary+safeString.h"

@interface FIRFriends() {
    NSMutableDictionary *profileChildObserverHandles;
}

@end

@implementation FIRFriends

static FIRFriends *instance;

+(FIRFriends *)sharedFriends {
    if (instance == nil) {
        instance = [FIRFriends new];
        instance.firstLoadedFlag = 0;
        instance->profileChildObserverHandles = [NSMutableDictionary new];
    }
    return instance;
}

- (FIRDatabaseReference *)databaseRef {
    return [[FIRDatabase database] reference];
}

- (NSString *)extractFullNameFromProfileDict:(NSDictionary *)profile {
    return [[profile safeStringForKey:@"first_name"] stringByAppendingFormat:@" %@", [profile safeStringForKey:@"last_name"]];
}

- (void)signOut {
    
    [[[__firFriendReference__ queryOrderedByChild:@"user1"] queryEqualToValue:[FIRPortlAuthenticator sharedAuthenticator].currentUser.uid] removeAllObservers];
    [[[__firFriendReference__ queryOrderedByChild:@"user2"] queryEqualToValue:[FIRPortlAuthenticator sharedAuthenticator].currentUser.uid] removeAllObservers];
    
    if (self.friendUsers != nil && [self.friendUsers allKeys].count > 0) {
        for (NSString *userId in [self.friendUsers allKeys]) {
            if ([profileChildObserverHandles objectForKey:[__firProfileReference__ child:userId].URL] != nil) {
                [[__firProfileReference__ child:userId] removeObserverWithHandle:[[profileChildObserverHandles objectForKey:[__firProfileReference__ child:userId].URL] integerValue]];
                [profileChildObserverHandles removeObjectForKey:[__firProfileReference__ child:userId].URL];
            }
        }
    }
    
    if ([profileChildObserverHandles allKeys].count > 0) {
        NSLog(@"There are still remains keys in Profile child observeHandles. - %@", profileChildObserverHandles);
        [profileChildObserverHandles removeAllObjects];
    }
    
    self.firstLoadedFlag = 0;
    self.friendUsers = [NSMutableDictionary new];
    
    
}

- (void)searchFriendByKeyword:(NSString *)keyword completed:(void(^)(NSArray *results, PortlError *error))completed {
    
    NSDate *time = [NSDate date];
    
    [__firProfileReference__ observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        
        NSMutableArray *testArray = [NSMutableArray new];
        if ([snapshot exists]) {
            for (FIRDataSnapshot *child in [[snapshot children] allObjects]) {
                NSDictionary *user = child.value;
                if (user != nil) {
                    if ([[[user safeStringForKey:@"email"] lowercaseString] containsString:[keyword lowercaseString]]
                        || [[[user safeStringForKey:@"first_name"] lowercaseString] containsString:[keyword lowercaseString]]
                        || [[[user safeStringForKey:@"last_name"] lowercaseString] containsString:[keyword lowercaseString]]
                        ) {
                        
                        if (![[user safeStringForKey:@"uid"] isEqualToString:[FIRPortlAuthenticator sharedAuthenticator].currentUser.uid]) {
                            [testArray addObject:user];
                        }
                    }
                }
            }
        }
        
        NSLog(@"Completed profile list check - %f", [[NSDate date] timeIntervalSince1970] - [time timeIntervalSince1970]);
        
        completed(testArray, nil);
    }];

}

- (NSString *)processFriendInfo:(NSDictionary *)friendInfo fromMe:(BOOL)fromMe snapKey:(NSString *)snapKey {
    
    NSString *userId = [friendInfo safeStringForKey:(fromMe ? @"user2" : @"user1")];
    
    if ([self.friendUsers safeDictionaryForKey:userId] == nil) {
        
        NSMutableDictionary *newFriendData = [@{@"uid":userId,
                                                @"status":[friendInfo safeStringForKey:@"status"],
                                                @"invited":[friendInfo safeStringForKey:@"invited"],
                                                @"accepted":[friendInfo safeStringForKey:@"accepted"],
                                                @"key":snapKey,
                                                @"sender":(fromMe ? @"me" : @"opponent")} mutableCopy];
        
        [self.friendUsers setObject:newFriendData forKey:userId];
        
        if ([profileChildObserverHandles objectForKey:[__firProfileReference__ child:userId].URL] != nil) {
            [[__firProfileReference__ child:userId] removeObserverWithHandle:[[profileChildObserverHandles objectForKey:[__firProfileReference__ child:userId].URL] integerValue]];
            [profileChildObserverHandles removeObjectForKey:[__firProfileReference__ child:userId].URL];
        }
        
        NSInteger handle = [[__firProfileReference__ child:userId] observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            if ([snapshot exists]) {
                NSDictionary *profile = snapshot.value;
                NSString *userId = [profile safeStringForKey:@"uid"];
                NSMutableDictionary *friendData = self.friendUsers[userId];
                friendData[@"profile"] = profile;
                self.friendUsers[userId] = friendData;
            } else {
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:gNotificationFriendListUpdated object:nil];
        }];
        
        [profileChildObserverHandles setObject:[NSNumber numberWithInteger:handle] forKey:[__firProfileReference__ child:userId].URL];
        
    } else {
        
        NSMutableDictionary *friendData = [self.friendUsers objectForKey:userId];
        
        friendData[@"status"] = friendInfo[@"status"];
        friendData[@"invited"] = friendInfo[@"invited"];
        friendData[@"accepted"] = [friendInfo safeStringForKey:@"accepted"];
        
        [self.friendUsers setObject:friendData forKey:userId];
        [[NSNotificationCenter defaultCenter] postNotificationName:gNotificationFriendListUpdated object:nil];
        
    }
    
    return userId;
}

- (void)processSnapshotForFriendChildSnap:(FIRDataSnapshot *)snapshot fromMe:(BOOL)fromMe {
    
    if ([snapshot exists]) {
        
        NSMutableArray *processedUserIds = [NSMutableArray new];
        
        for (FIRDataSnapshot *child in [[snapshot children] allObjects]) {
            
            NSDictionary *friendInfo = child.value;
            if (friendInfo != nil) {
                if (![[friendInfo safeStringForKey:@"status"] isEqualToString:@"d"]) {
                    NSString *processedUserId = [self processFriendInfo:friendInfo fromMe:fromMe snapKey:child.key];
                    [processedUserIds addObject:processedUserId];
                }
            }
        }
        
        [self removeRemovedFriendsFor:processedUserIds fromMe:fromMe];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:gNotificationFriendListUpdated object:nil];
        
    } else {
        
        [self removeRemovedFriendsFor:nil fromMe:fromMe];
        [[NSNotificationCenter defaultCenter] postNotificationName:gNotificationFriendListUpdated object:nil];
        
    }
    
}

- (void)removeRemovedFriendsFor:(NSArray *)processedUserIds fromMe:(BOOL)fromMe {
    
    NSArray *existingUserIds = [self.friendUsers allKeys];
    
    for (NSString *userId in existingUserIds) {
        if ((processedUserIds == nil || ![processedUserIds containsObject:userId]) &&
            ((fromMe && [[[self.friendUsers objectForKey:userId] safeStringForKey:@"sender"] isEqualToString:@"me"]) || (!fromMe && [[[self.friendUsers objectForKey:userId] safeStringForKey:@"sender"] isEqualToString:@"opponent"]))) {
            
            if ([profileChildObserverHandles objectForKey:[__firProfileReference__ child:userId].URL] != nil) {
                [[__firProfileReference__ child:userId] removeObserverWithHandle:[[profileChildObserverHandles objectForKey:[__firProfileReference__ child:userId].URL] integerValue]];
                [profileChildObserverHandles removeObjectForKey:[__firProfileReference__ child:userId].URL];
            }
            
            [self.friendUsers removeObjectForKey:userId];
        
        }
    }
}

- (void)fetchMyFriends {
    
    if (![[FIRPortlAuthenticator sharedAuthenticator] authorized]) {
        return;
    }
    
    self.friendUsers = [NSMutableDictionary new];
    
    self.firstLoadedFlag = 0;
    
    [[[__firFriendReference__ queryOrderedByChild:@"user1"] queryEqualToValue:[FIRPortlAuthenticator sharedAuthenticator].currentUser.uid] observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        
        [self processSnapshotForFriendChildSnap:snapshot fromMe:YES];
        
        self.firstLoadedFlag++;
        
    }];
    
    [[[__firFriendReference__ queryOrderedByChild:@"user2"] queryEqualToValue:[FIRPortlAuthenticator sharedAuthenticator].currentUser.uid] observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        
        [self processSnapshotForFriendChildSnap:snapshot fromMe:NO];
        self.firstLoadedFlag++;
        
    }];
}

- (NSString *)friendStatusForUserId:(NSString *)userId {

    if (self.friendUsers == nil) return nil;
    
    NSDictionary *friend = self.friendUsers[userId];
    if (friend == nil) {
        return nil;
    } else {
        if ([[friend safeStringForKey:@"status"] isEqualToString:@"c"]) {
            return FRIEND_CONNECTED;
        } else if ([[friend safeStringForKey:@"status"] isEqualToString:@"i"]) {
            if ([[friend safeStringForKey:@"sender"] isEqualToString:@"me"]) {
                return FRIEND_INVITE_SENT;
            } else if ([[friend safeStringForKey:@"sender"] isEqualToString:@"opponent"]) {
                return FRIEND_WAITING_ACCEPT;
            }
        } else if ([[friend safeStringForKey:@"status"] isEqualToString:@"d"]) {
            return FRIEND_DECLINED;
        }
    }
    
    return nil;
}

- (NSArray *)friendIDs {
    if (self.friendUsers == nil) return nil;
    return [self.friendUsers allKeys];
}

- (NSArray *)listOfFrinds {
    if (self.friendUsers == nil) return nil;
    return [self.friendUsers allValues];
}

- (void)sendFriendInviteTo:(NSString *)uid completed:(void(^)(PortlError *error))completed {
    
    NSString *key = [[[self databaseRef] child:@"v2/friend"] childByAutoId].key;
    NSDictionary *friend = @{@"user1": [FIRPortlAuthenticator sharedAuthenticator].currentUser.uid,
                             @"user2": uid,
                             @"status": @"i",
                             @"invited": [DateUtility stringFromDate:[NSDate date] toFormat:@"yyyy-MM-dd HH:mm:ss z"]};
    
    NSDictionary *childUpdates = @{[@"/v2/friend/" stringByAppendingString:key]: friend};
    
    [[self databaseRef] updateChildValues:childUpdates withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
        if (error == nil) {
			
            if (completed != nil) {
                completed(nil);
            }
            
        } else {
            completed([PortlError errorWithError:error code:0 message:nil]);
        }
    }];
    
}

- (void)sendFriendInviteToFacebookId:(NSString *)facebookId completed:(void(^)(PortlError *error))completed {
    [[[__firProfileReference__ queryOrderedByChild:@"fb_id"] queryEqualToValue:facebookId] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        if ([snapshot exists]) {
            NSDictionary *userInformation = ((FIRDataSnapshot *)[snapshot.children allObjects][0]).value;
            NSString *userId = [userInformation safeStringForKey:@"uid"];
            if (userInformation != nil) {
                [self sendFriendInviteTo:userId completed:completed];
            }
        }
        
        return;
    }];
}

- (void)acceptFriendInvitationFrom:(NSString *)uid completed:(void(^)(PortlError *error))completed {
    
    [[[__firFriendReference__ queryOrderedByChild:@"user1"] queryEqualToValue:uid] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        if ([snapshot exists]) {
            for (FIRDataSnapshot *child in [[snapshot children] allObjects]) {
                NSDictionary *data = child.value;
                if ([[data safeStringForKey:@"user2"] isEqualToString:[FIRPortlAuthenticator sharedAuthenticator].currentUser.uid]) {
                    
                    NSString *key = child.key;
                    NSMutableDictionary *newFriendData = [data mutableCopy];
                    newFriendData[@"status"] = @"c";
                    newFriendData[@"accepted"] = [DateUtility stringFromDate:[NSDate date] toFormat:@"yyyy-MM-dd HH:mm:ss z"];
                    
                    NSDictionary *childUpdated = @{[@"/v2/friend/" stringByAppendingString:key]: newFriendData};
                    [[self databaseRef] updateChildValues:childUpdated withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
                        
                        if (error == nil) {
                            
                            completed(nil);
                            
                        } else {
                            completed([PortlError errorWithError:error code:0 message:nil]);
                        }
                        
                    }];
                    
                    return;
                }
            }
        } else {
            completed([PortlError errorWithError:nil code:PERRCODE_UNKNOWN_FIREBASE_ERROR message:PERR_UNKNOWN_FIREBASE_ERROR]);
        }
    }];
}

- (void)resendFriendInviteTo:(NSString *)uid completed:(void(^)(PortlError *error))completed {
    
    NSString *friendInfoKey;
    if (self.friendUsers != nil) {
        NSDictionary *friend = [self.friendUsers safeDictionaryForKey:uid];
        if (friend != nil) {
            friendInfoKey = [friend safeStringForKey:@"key"];
        }
    }
    
    if (friendInfoKey == nil) {
        completed([PortlError errorWithError:nil code:PERRCODE_UNKNOWN_ERROR message:PERR_UNKNOWN_ERROR]);
        return;
    }
    
    [[[__firFriendReference__ child:friendInfoKey] child:@"invited"] setValue:[DateUtility stringFromDate:[NSDate date] toFormat:@"yyyy-MM-dd HH:mm:ss z"] withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
        
        if (error == nil) {
			
            completed(nil);
        } else {
            completed([PortlError errorWithError:error code:0 message:nil]);
        }
    }];
}

- (void)declineFriendInvitationFrom:(NSString *)uid completed:(void(^)(PortlError *error))completed {
    [[[__firFriendReference__ queryOrderedByChild:@"user1"] queryEqualToValue:uid] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        if ([snapshot exists]) {
            for (FIRDataSnapshot *child in [[snapshot children] allObjects]) {
                NSDictionary *data = child.value;
                if ([[data safeStringForKey:@"user2"] isEqualToString:[FIRPortlAuthenticator sharedAuthenticator].currentUser.uid]) {
                    
                    NSString *key = child.key;
                    NSMutableDictionary *newFriendData = [data mutableCopy];
                    newFriendData[@"status"] = @"d";
                    newFriendData[@"declined"] = [DateUtility stringFromDate:[NSDate date] toFormat:@"yyyy-MM-dd HH:mm:ss z"];
                    
                    NSDictionary *childUpdated = @{[@"/v2/friend/" stringByAppendingString:key]: newFriendData};
                    
                    [[self databaseRef] updateChildValues:childUpdated withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
                        
                        if (error == nil) {
							
                            completed(nil);
                            
                        } else {
                            completed([PortlError errorWithError:error code:0 message:nil]);
                        }
                        
                    }];
                    
                    return;
                }
            }
        } else {
            completed([PortlError errorWithError:nil code:PERRCODE_UNKNOWN_FIREBASE_ERROR message:PERR_UNKNOWN_FIREBASE_ERROR]);
        }
    }];
}

- (void)searchProfileByFacebookId:(NSString *)facebookId completed:(void(^)(NSString *fbId, BOOL found))completed {
    [[[__firProfileReference__ queryOrderedByChild:@"fb_id"] queryEqualToValue:facebookId] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        if ([snapshot exists]) {
            if (completed) {
                completed(facebookId, YES);
                return;
            }
        }
        
        completed(facebookId, NO);
        return;
    }];
}

- (NSArray *)listOfConnectedFriends {
    NSArray *friends = [self listOfFrinds];
    if (friends == nil) {
        return nil;
    }
    NSMutableArray *connectedFriends = [NSMutableArray new];
    for (NSDictionary *friend in friends) {
        if ([[friend safeStringForKey:@"status"] isEqualToString:@"c"]) {
            [connectedFriends addObject:friend];
        }
    }
    [connectedFriends sortUsingComparator:^NSComparisonResult(NSDictionary*  _Nonnull obj1, NSDictionary*  _Nonnull obj2) {
        NSDictionary *profile1 = [obj1 safeDictionaryForKey:@"profile"];
        NSDictionary *profile2 = [obj2 safeDictionaryForKey:@"profile"];
        
        if (profile1 != nil && profile2 != nil) {
            return [[[self extractFullNameFromProfileDict:profile1] lowercaseString] compare:[[self extractFullNameFromProfileDict:profile2] lowercaseString]];
        } else {
            return NSOrderedSame;
        }
    }];
    return connectedFriends;
}

- (int)checkFriendShipForUser:(NSString *)userId {
    if (self.friendUsers == nil) {
        return 0;
    }
    
    if ([self.friendUsers safeDictionaryForKey:userId] == nil) {
        return 0;
    }
    
    NSDictionary *friend = [self.friendUsers safeDictionaryForKey:userId];
    
    if ([[friend safeStringForKey:@"status"] isEqualToString:@"c"]) {
        return 1;
    } else {
        if ([[friend safeStringForKey:@"sender"] isEqualToString:@"me"]) {
            NSDate *invited = [DateUtility dateFromString:[friend safeStringForKey:@"invited"] fromFormat:@"yyyy-MM-dd HH:mm:ss z"];
            if ([[NSDate date] timeIntervalSince1970] - [invited timeIntervalSince1970] < 10 * 60) {
                return 4;
            } else {
                return 2;
            }
        } else {
            return 3;
        }
    }
    
}

- (int)friendsCountWaitingForAcceptance {
    NSArray *listOfFriends = [self listOfFrinds];
    int count = 0;
    for (NSDictionary *friend in listOfFriends) {
        if ([[friend safeStringForKey:@"status"] isEqualToString:@"i"]) {
            if ([[friend safeStringForKey:@"sender"] isEqualToString:@"opponent"]) {
                count++;
            }
        }
    }
    return count;
}

- (void)sendNotificationToFriendsForEventJoin:(PortlEvent *)event {
    NSArray *connectedFriends = [self listOfConnectedFriends];    
    NSMutableDictionary* eventDictionary = [[NSMutableDictionary alloc] initWithDictionary:@{@"key": event.identifier, @"title": event.title}];
    if (event.imageURL != nil) {
        [eventDictionary setObject:event.imageURL forKey:@"image"];
    }
}

@end
