//
//  PortlError.m
//  Portl iOS Application
//  Created by Portl LLC on 2017/04/29.
//  Copyright © 2017 Portl LLC. All rights reserved.
//

#import "PortlError.h"

@implementation PortlError

+(PortlError *)errorWithError:(NSError *)error code:(int)code message:(NSString *)message {
    return [[PortlError alloc] initWithError:error code:code message:message];
}

-(id)initWithError:(NSError *)error code:(int)code message:(NSString *)message {
    self = [super init];
    if (self) {
        self.error = error;
        self.customizedErrorCode = code;
        self.customizedErrorMessage = message;
    }
    return self;
}

@end
