//
//  DataKeeper.m
//  Portl
//
//  Created by Messia Engineer on 10/18/16.
//  Copyright © 2016 Portl. All rights reserved.
//

#import "DataKeeper.h"
#include <CommonCrypto/CommonDigest.h>

@implementation DataKeeper

static DataKeeper   *instance;

+ (DataKeeper *)keeper {
    if (!instance) {
        instance = [DataKeeper new];
    }
    
    return instance;
}

- (void)saveDeviceLocation:(CLLocation *)location {
    self.deviceLocation = location;
}

- (CLLocation *)getDeviceLocation {
    return self.deviceLocation;
}

- (void)saveTokenAndUserInfo {
    if (self.authToken != nil && self.userInfo != nil) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"user-saved"];
        [[NSUserDefaults standardUserDefaults] setObject:self.authToken forKey:@"auth-token"];
        [[NSUserDefaults standardUserDefaults] setObject:self.userInfo forKey:@"user-info"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)removeTokenAndUserInfo {
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"user-saved"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"auth-token"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"user-info"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    self.authToken = nil;
    self.userInfo = nil;
}

- (BOOL) userInfoSaved {
    BOOL saved = [[NSUserDefaults standardUserDefaults] boolForKey:@"user-saved"];
    BOOL tokenSaved = ([[NSUserDefaults standardUserDefaults] objectForKey:@"auth-token"] != nil);
    BOOL userInfoSaved = ([[NSUserDefaults standardUserDefaults] objectForKey:@"user-info"] != nil);
    return saved && tokenSaved && userInfoSaved;
}

- (void)loadTokenAndUserInfo {
    self.authToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"auth-token"];
    self.userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:@"user-info"];
}

- (BOOL)isGuestLogin {
    
    if (self.userInfo == nil) return NO;
    
    if ([self.userInfo safeBooleanValueForKey:@"is_guest"]) {
        return YES;
    }
    
    return NO;
}

-(NSString*) sha256:(NSString *)clear{
    const char *s=[clear cStringUsingEncoding:NSASCIIStringEncoding];
    NSData *keyData=[NSData dataWithBytes:s length:strlen(s)];
    
    uint8_t digest[CC_SHA256_DIGEST_LENGTH]={0};
    CC_SHA256(keyData.bytes, keyData.length, digest);
    NSData *out=[NSData dataWithBytes:digest length:CC_SHA256_DIGEST_LENGTH];
    NSString *hash=[out description];
    hash = [hash stringByReplacingOccurrencesOfString:@" " withString:@""];
    hash = [hash stringByReplacingOccurrencesOfString:@"<" withString:@""];
    hash = [hash stringByReplacingOccurrencesOfString:@">" withString:@""];
    return hash;
}

- (NSString *)profileAvatarUrl:(NSString *)avatarId {
    // c41ec0f6-d559-405f-a7a4-b9ea1bd9a06b.jpg
    // c41ec0f6-d559-405f-a7a4-b9ea1bd9a06b.jpg
    return [NSString stringWithFormat:@"https://storage.googleapis.com/portldev.appspot.com/avatar/%@", avatarId];
}

- (NSArray *)favoriteEvents {
    
    NSInteger favoriteEventsCount = [[NSUserDefaults standardUserDefaults] integerForKey:@"favorite_events_count"];
    if (favoriteEventsCount > 0) {
        NSMutableArray *events = [NSMutableArray new];
        for (int idx = 0; idx < favoriteEventsCount; idx++) {
            NSString *event = [[NSUserDefaults standardUserDefaults] stringForKey:[NSString stringWithFormat:@"favorite_event-%d", (int)idx]];
            if (event != nil) {
                PortlEvent *portlEvent = [PortlEvent eventWithJSONString:event];
                if (portlEvent != nil) {
                    [events addObject:portlEvent];
                }
            }
        }
        return events;
    }
    return nil;
    
}

- (void)addFavoriteEvent:(PortlEvent *)event {
    
    if ([self eventIsFavoriteFor:event]) {
        return;
    }
    
    NSArray *events = [self favoriteEvents];
    
    NSMutableArray *newEvents = [NSMutableArray new];
    
    if (events != nil) {
        newEvents = [events mutableCopy];
    }
    
    [newEvents addObject:event];
    [self fullSaveFavoritesArray:newEvents];
}

- (BOOL)eventIsFavoriteFor:(PortlEvent *)event {
    NSArray *favorites = [self favoriteEvents];
    if (favorites == nil) return NO;
    for (PortlEvent *favorite in favorites) {
        if ([event isEqualEvent:favorite]) {
            return YES;
        }
    }
    return NO;
}

- (void)removeFromFavoritesFor:(PortlEvent *)event {
    NSArray *favorites = [self favoriteEvents];
    
    NSMutableArray *newArray = [NSMutableArray new];
    if (favorites != nil) {
        newArray = [favorites mutableCopy];
    }
    
    for (PortlEvent *favorite in newArray) {
        if ([favorite isEqualEvent:event]) {
            [newArray removeObject:favorite];
            break;
        }
    }
    
    [self fullSaveFavoritesArray:newArray];
}

- (void)fullSaveFavoritesArray:(NSArray *)events {
    
    // Clean first
    NSInteger favoriteEventsCount = [[NSUserDefaults standardUserDefaults] integerForKey:@"favorite_events_count"];
    if (favoriteEventsCount > 0) {
        for (int idx = 0; idx < favoriteEventsCount; idx++) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"favorite_event-%d", (int)idx]];
        }
    }
    
    if (events != nil) {
        [[NSUserDefaults standardUserDefaults] setInteger:events.count forKey:@"favorite_events_count"];
        for (int idx = 0; idx < events.count; idx++) {
            PortlEvent *event = [events objectAtIndex:idx];
            [[NSUserDefaults standardUserDefaults] setObject:[event toJSONString] forKey:[NSString stringWithFormat:@"favorite_event-%d", (int)idx]];
        }
    } else {
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"favorite_events_count"];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

@end
