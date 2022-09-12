//
//  Constants.h
//  Remi
//
//  Created by Portl LLC on 1/21/16.
//  Copyright © 2016 Remi Pty Lt. All rights reserved.
//

#ifndef Constants_h
#define Constants_h

#import <Foundation/Foundation.h>

#define METERS_ONE_MILE                 1609.34

#define gNotificationLocationChanged            @"gNotificationLocationChanged"
#define gNotificationUserProfileUpdated         @"gNotificationUserProfileUpdated"
#define gNotificationFriendListUpdated          @"gNotificationFriendListUpdated"
#define gNotificationNotificationListUpdated    @"gNotificationNotificationListUpdated"
#define gNotificationMessageRoomsUpdated        @"gNotificationMessageRoomsUpdated"
#define gNotificationMyVenueRemoved             @"gNotificationMyVenueRemoved"
#define gNotificationEventCreated               @"gNotificationEventCreated"
#define gNotificationMyInterestsUpdated         @"gNotificationMyInterestsUpdated"
#define gNotificationOpenMyFriends				@"gNotificationOpenMyFriends"
#define gNotificationOpenDirectMessage			@"gNotificationOpenDirectMessage"
#define gNotificationApiDeprecation				@"gNotificationApiDeprecation"
#define gNotificationOpenEventDetail			@"gNotificationOpenEventDetail"
#define gNotificationHomeButtonPressed			@"gNotificationHomeButtonPressed"

#if defined(STAGING) && defined(QA)

#define FCM_SERVER_KEY                  @"AAAARv7xP8s:APA91bHtMwc7sWAYCZq8K6BYdmuZwnUyss3Awo0iVxum8U94xxvlIggW7cvCfTOAm1Dy341dvOobKswMd7iaiN-x8sZrfIczjvwUW0LG1BxVMNz1BIooUGbD1aMHbHlJK3dexzrYjhAz"
#define FCM_SENDER_ID                   @"304924934091"

#else

#define FCM_SERVER_KEY                  @"AAAAbaSfMO4:APA91bGg3M9DIup075uaLusuIcZblN0xcb7YLdItaq1EFvh8U-ENZUNDfCnLyIi8T8BeCtsMwgFZtc2RaqRqYAu7BHW-i_XtiObWgcT6tLm7DMicWqyx9ckUiatDkYfLEJbGF1EpAcqb"
#define FCM_SENDER_ID                   @"470913331438"

#endif

#define MAPS_API_KEY 					@"AIzaSyB3XlIO6pA1mspKMkc5TFNyJ9FT4jEUpUM"

#endif /* Constants_h */


