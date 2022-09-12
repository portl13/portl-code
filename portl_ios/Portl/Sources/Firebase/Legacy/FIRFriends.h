//
//  FIRFriends.h
//  Portl iOS Application
//  Created by Portl LLC on 2017/05/02.
//  Copyright © 2017 Portl LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PortlError.h"
#import <Service/Service.h>

#define FRIEND_CONNECTED        @"connected"
#define FRIEND_INVITE_SENT      @"invite Sent"
#define FRIEND_WAITING_ACCEPT   @"accepting"
#define FRIEND_DECLINED         @"declined"

@interface FIRFriends : NSObject

+(FIRFriends *)sharedFriends;

@property (strong, nonatomic) NSMutableDictionary<NSString *, NSMutableDictionary *> *friendUsers;

@property (readwrite, nonatomic) NSInteger firstLoadedFlag;

- (void)searchFriendByKeyword:(NSString *)keyword completed:(void(^)(NSArray *results, PortlError *error))completed;
- (void)fetchMyFriends;
- (NSString *)friendStatusForUserId:(NSString *)userId;
- (NSArray *)listOfFrinds;
- (NSArray *)listOfConnectedFriends;
- (NSArray *)friendIDs;

- (void)signOut;

- (void)sendFriendInviteTo:(NSString *)uid completed:(void(^)(PortlError *error))completed;
- (void)acceptFriendInvitationFrom:(NSString *)uid completed:(void(^)(PortlError *error))completed;
- (void)resendFriendInviteTo:(NSString *)uid completed:(void(^)(PortlError *error))completed;
- (void)declineFriendInvitationFrom:(NSString *)uid completed:(void(^)(PortlError *error))completed;
- (void)sendFriendInviteToFacebookId:(NSString *)facebookId completed:(void(^)(PortlError *error))completed;

- (void)searchProfileByFacebookId:(NSString *)facebookId completed:(void(^)(NSString *fbId, BOOL found))completed;

- (int)checkFriendShipForUser:(NSString *)userId;  // 0 : no-friend, 1 : friend, 2 : you sent invitation, 3 : waiting for your accept, 4 : sent before 5 mins ago
- (int)friendsCountWaitingForAcceptance;

- (void)sendNotificationToFriendsForEventJoin:(PortlEvent *)event;

@end
