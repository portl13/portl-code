//
//  NSString (measureWithFont).m
//  holistica
//
//  Created by Mountain on 11/2/13.
//  Copyright (c) 2013 chinasoft. All rights reserved.
//

#import "NSString+formatCheck.h"

@implementation NSString (formatCheck)

-(BOOL) isValidEmailAddress {
    
    BOOL stricterFilter = YES;
    NSString *stricterFilterString = @"[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}";
    NSString *laxString = @".+@([A-Za-z0-9]+\\.)+[A-Za-z]{2}[A-Za-z]*";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:self];

}

@end
