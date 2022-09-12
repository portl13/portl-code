//
//  DataKeeper.h
//  Portl
//
//  Created by Messia Engineer on 10/18/16.
//  Copyright © 2016 Portl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "PortlEvent.h"

@interface DataKeeper : NSObject

+ (DataKeeper *)keeper;

@property (strong, nonatomic) CLLocation    *deviceLocation;
@property (strong, nonatomic) NSString      *authToken;
@property (strong, nonatomic) NSDictionary  *userInfo;

- (void)saveTokenAndUserInfo;
- (void)removeTokenAndUserInfo;
- (BOOL)userInfoSaved;
- (void)loadTokenAndUserInfo;

- (BOOL)isGuestLogin;

- (void)saveDeviceLocation:(CLLocation *)location;
- (CLLocation *)getDeviceLocation;
- (NSString*) sha256:(NSString *)clear;

- (NSString *)profileAvatarUrl:(NSString *)avatarId;

- (NSArray *)favoriteEvents;
- (void)addFavoriteEvent:(PortlEvent *)event;
- (BOOL)eventIsFavoriteFor:(PortlEvent *)event;
- (void)removeFromFavoritesFor:(PortlEvent *)event;

@end
