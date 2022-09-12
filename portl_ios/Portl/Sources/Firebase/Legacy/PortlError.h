//
//  PortlError.h
//  Portl iOS Application
//  Created by Portl LLC on 2017/04/29.
//  Copyright © 2017 Portl LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#define PERR_EMAIL_ALREADY_TAKEN            @"Email already taken."
#define PERR_USERNAME_ALREADY_TAKEN			@"Username already taken."
#define PERR_UNKNOWN_FIREBASE_ERROR         @"Unknown Firebase Error."
#define PERR_UNKNOWN_ERROR                  @"Unknown Error."
#define PERR_INVALID_EMAIL                  @"Email is invalid."
#define PERR_INVALID_PASSWORD               @"Incorrect Password."
#define PERR_NOT_AUTHORIZED                 @"Not authorized."
#define PERR_FIREBASE_ACTION_CANCELED       @"Firebase action canceled."
#define PERR_NEED_PASSWORD_FORDEV           @"Need password for dev"
#define PERR_USER_DELETED                   @"User deleted from the server."
#define PERR_OTHER_USER_CONNECTED_FB_ID     @"This facebook id has already connected to the other user."
#define PERR_NO_FRIENDS_TO_SHARE            @"No friends to share"

#define PERRCODE_EMAIL_ALREADY_TAKEN        100
#define PERRCODE_INVALID_EMAIL              101
#define PERRCODE_INVALID_PASSWORD           102
#define PERRCODE_NOT_AUTHORIZED             103
#define PERRCODE_NEED_PASSWORD_FORDEV       104
#define PERRCODE_USER_DELETED               105
#define PERRCODE_OTHER_USER_CONNECTED_FB_ID 106
#define PERRCODE_NO_FRIENDS_TO_SHARE        107
#define PERRCODE_USERNAME_ALREADY_TAKEN		108

#define PERRCODE_FIREBASE_ACTION_CANCELED   997
#define PERRCODE_UNKNOWN_FIREBASE_ERROR     998
#define PERRCODE_UNKNOWN_ERROR              999


@interface PortlError : NSObject

@property (strong, nonatomic) NSError *error;
@property (readwrite, nonatomic) int customizedErrorCode;
@property (strong, nonatomic) NSString *customizedErrorMessage;

+(PortlError *)errorWithError:(NSError *)error code:(int)code message:(NSString *)message;

@end
